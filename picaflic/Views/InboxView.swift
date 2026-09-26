import SwiftUI

struct InboxView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var inboxStore: InboxStore

    private let friendsService = FriendsService()
    private let inboxService = InboxService()
    private let messageService = MessageService()
    private let personalWatchlistService = PersonalWatchlistService()

    @State private var pendingFriendRequests: [FriendUser] = []
    @State private var watchlistRequests: [WatchlistRequestItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var messages: [Message] = []

    var body: some View {
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
                    ScrollView {
                        VStack(spacing: 16) {

                            inboxBlock(title: "Messages") {
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

                            inboxBlock(title: "Friend Requests") {
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

                            inboxBlock(title: "Watchlist Requests") {
                                if watchlistRequests.isEmpty {
                                    emptyBlockMessage("No watchlist invites right now.")
                                } else {
                                    ForEach(watchlistRequests) { request in
                                        watchlistRequestRow(request)
                                        if request.id != watchlistRequests.last?.id {
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
                        .padding(.bottom, 110)
                    }
                    .refreshable { await loadInbox() }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadInbox() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 16)

            HStack(alignment: .center, spacing: 12) {
                Spacer()

                VStack(alignment: .center, spacing: -4) {
                    Text("You've Got")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color("BrandTeal"))
                    Text("Mail!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color("BrandTeal"))
                }
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

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Row Views

    private func messageRow(_ message: Message) -> some View {
        let otherId = message.other_user_id ?? message.sender_id

        return NavigationLink {
            MessageComposeView(
                recipient: FriendUser(
                    id: otherId,
                    display_name: message.sender_name,
                    email: ""
                ),
                token: authStore.accessToken ?? "",
                existingMessage: message
            )
        } label: {
            HStack(spacing: 12) {
                Image("EnvelopeIcon")
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

    private func watchlistRequestRow(_ request: WatchlistRequestItem) -> some View {
        HStack(spacing: 12) {
            Image("PlayButton")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.watchlistName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                Text("From: \(request.fromName)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                Task { await accept(request) }
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
                Task { await decline(request) }
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
            async let sharesResponse = personalWatchlistService.fetchReceivedShares(token: token)
            async let messagesResponse = messageService.fetchMessages(token: token)

            let friends = try await friendsResponse
            let invites = try await invitesResponse
            let shares = try await sharesResponse
            let msgs = try await messagesResponse

            messages = msgs
            pendingFriendRequests = friends.pending_received

            let inviteItems = invites.map { WatchlistRequestItem.groupInvite($0) }
            let shareItems = shares
                .filter { $0.status == "pending" }
                .map { WatchlistRequestItem.personalShare($0) }
            watchlistRequests = inviteItems + shareItems

            await inboxStore.refresh(token: token)
        } catch is CancellationError {
            // A previous load was superseded (e.g. quick tab switching) — not a real failure.
        } catch let error as URLError where error.code == .cancelled {
            // Same as above, surfaced via URLSession instead of Swift concurrency.
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

    private func accept(_ request: WatchlistRequestItem) async {
        guard let token = authStore.accessToken else { return }
        do {
            switch request {
            case .groupInvite(let invite):
                try await inboxService.acceptWatchlistInvite(token: token, inviteId: invite.id)
            case .personalShare(let share):
                try await personalWatchlistService.acceptShare(token: token, shareId: share.share_id)
            }
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func decline(_ request: WatchlistRequestItem) async {
        guard let token = authStore.accessToken else { return }
        do {
            switch request {
            case .groupInvite(let invite):
                try await inboxService.declineWatchlistInvite(token: token, inviteId: invite.id)
            case .personalShare(let share):
                try await personalWatchlistService.declineShare(token: token, shareId: share.share_id)
            }
            await loadInbox()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Unified watchlist request row model

/// Wraps the two distinct "watchlist request" types — group watchlist invites
/// (`WatchlistInviteItem`, from the friends-group Watchlist system) and personal
/// watchlist shares (`PersonalWatchlistShare`, from the personal-watchlist sharing
/// system) — into one type so the Inbox can list and act on both in a single block.
enum WatchlistRequestItem: Identifiable {
    case groupInvite(WatchlistInviteItem)
    case personalShare(PersonalWatchlistShare)

    var id: String {
        switch self {
        case .groupInvite(let item): return "invite-\(item.id)"
        case .personalShare(let item): return "share-\(item.share_id)"
        }
    }

    var watchlistName: String {
        switch self {
        case .groupInvite(let item): return item.watchlist_name
        case .personalShare(let item): return item.watchlist_name
        }
    }

    var fromName: String {
        switch self {
        case .groupInvite(let item): return item.invited_by_name
        case .personalShare(let item): return item.owner_display_name
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
