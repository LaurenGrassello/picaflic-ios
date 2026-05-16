import SwiftUI

struct InboxView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var inboxStore: InboxStore

    private let friendsService = FriendsService()
    private let inboxService = InboxService()
    private let messageService = MessageService()

    @State private var pendingFriendRequests: [FriendUser] = []
    @State private var watchlistInvites: [WatchlistInviteItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var messages: [Message] = []
    @State private var replyToMessage: Message? = nil
    @State private var showReplySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    if isLoading {
                        Spacer()
                        ProgressView("Loading inbox...")
                            .tint(Color("BrandSand"))
                            .foregroundStyle(Color("BrandSand"))
                        Spacer()
                    } else if !errorMessage.isEmpty {
                        Spacer()
                        Text(errorMessage)
                            .foregroundStyle(Color("BrandRust"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Spacer()
                    } else {
                        GeometryReader { geo in
                            VStack(spacing: 16) {
                                
                                inboxBlock(
                                    title: "Messages",
                                    height: (geo.size.height - 72) / 3
                                ) {
                                    if messages.isEmpty {
                                        emptyBlockMessage("No messages yet.")
                                    } else {
                                        ForEach(messages) { message in
                                            messageRow(message)
                                            if message.id != messages.last?.id {
                                                Divider()
                                                    .background(Color.white.opacity(0.08))
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }

                                // Friend Requests Block
                                inboxBlock(
                                    title: "Friend Requests",
                                    height: (geo.size.height - 72) / 3
                                ) {
                                    if pendingFriendRequests.isEmpty {
                                        emptyBlockMessage("No friend requests right now.")
                                    } else {
                                        ForEach(pendingFriendRequests) { user in
                                            friendRequestRow(user)
                                            if user.id != pendingFriendRequests.last?.id {
                                                Divider()
                                                    .background(Color.white.opacity(0.08))
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }

                                // Watchlist Invites Block
                                inboxBlock(
                                    title: "Watchlist Requests",
                                    height: (geo.size.height - 72) / 3
                                ) {
                                    if watchlistInvites.isEmpty {
                                        emptyBlockMessage("No watchlist invites right now.")
                                    } else {
                                        ForEach(watchlistInvites) { invite in
                                            watchlistInviteRow(invite)
                                            if invite.id != watchlistInvites.last?.id {
                                                Divider()
                                                    .background(Color.white.opacity(0.08))
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .task { await loadInbox() }
            .refreshable { await loadInbox() }
            .sheet(isPresented: $showReplySheet) {
                if let message = replyToMessage,
                   let token = authStore.accessToken {
                    // Build a FriendUser from the message sender
                    let sender = FriendUser(
                        id: message.sender_id,
                        display_name: message.sender_name,
                        email: ""
                    )
                    MessageComposeView(
                        recipient: sender,
                        token: token,
                        existingMessage: message,
                        onDismiss: {
                            showReplySheet = false
                            replyToMessage = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            // Centered eye logo
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // You've Got Mail row — text tilted, asset to the right
            HStack(alignment: .center, spacing: 12) {
                Spacer()

                Text("You've Got Mail!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color("BrandTeal"))
                    .rotationEffect(.degrees(-8))
                    .fixedSize()

                Image("YouveGotMail")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    // MARK: - Block Builder

    private func inboxBlock<Content: View>(
        title: String,
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("BrandTeal"))

            ScrollView {
                VStack(spacing: 0) {
                    content()
                }
            }
            .background(Color.white.opacity(0.05))
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Row Views
    
    private func messageRow(_ message: Message) -> some View {
        Button {
            replyToMessage = message
            showReplySheet = true
        } label: {
            HStack(spacing: 12) {
                Image("Inbox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(message.subject)
                            .font(.subheadline.weight(message.isUnread ? .bold : .regular))
                            .foregroundStyle(Color("BrandGold"))
                            .lineLimit(1)

                        if message.isUnread {
                            Circle()
                                .fill(Color("BrandTeal"))
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text("From: \(message.sender_name)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func friendRequestRow(_ user: FriendUser) -> some View {
        HStack(spacing: 12) {
            Image("YellowFriend")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.display_name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                Task { await acceptFriend(user) }
            } label: {
                Text("Accept")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("BrandTeal"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Task { await declineFriend(user) }
            } label: {
                Text("Decline")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("BrandRust"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func watchlistInviteRow(_ invite: WatchlistInviteItem) -> some View {
        HStack(spacing: 12) {
            Image("PlayButton")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.watchlist_name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                Text("From: \(invite.invited_by_name)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                Task { await acceptInvite(invite) }
            } label: {
                Text("Accept")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("BrandTeal"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Task { await declineInvite(invite) }
            } label: {
                Text("Decline")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("BrandRust"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func emptyBlockMessage(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(16)
    }

    // MARK: - Data

    private func loadInbox() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            async let friendsResponse = friendsService.fetchFriends(token: token)
            async let invitesResponse = inboxService.fetchWatchlistInvites(token: token)
            async let messagesResponse = messageService.fetchMessages(token: token)
            
            let friends = try await friendsResponse
            let invites = try await invitesResponse
            let msgs = try await messagesResponse
            
            messages = msgs
            pendingFriendRequests = friends.pending_received
            watchlistInvites = invites

            await inboxStore.refresh(token: token)
        } catch {
            errorMessage = error.localizedDescription
            print("LOAD INBOX ERROR:", error)
        }

        isLoading = false
    }

    private func acceptFriend(_ user: FriendUser) async {
        guard let token = authStore.accessToken else { return }
        do {
            try await friendsService.acceptFriend(token: token, userId: user.id)
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func declineFriend(_ user: FriendUser) async {
        guard let token = authStore.accessToken else { return }
        do {
            try await friendsService.declineFriend(token: token, userId: user.id)
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func acceptInvite(_ invite: WatchlistInviteItem) async {
        guard let token = authStore.accessToken else { return }
        do {
            try await inboxService.acceptWatchlistInvite(token: token, inviteId: invite.id)
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func declineInvite(_ invite: WatchlistInviteItem) async {
        guard let token = authStore.accessToken else { return }
        do {
            try await inboxService.declineWatchlistInvite(token: token, inviteId: invite.id)
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        InboxView()
            .environmentObject(AuthStore())
            .environmentObject(InboxStore())
    }
}
