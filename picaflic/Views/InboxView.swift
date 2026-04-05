import SwiftUI

struct InboxView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var inboxStore: InboxStore

    private let friendsService = FriendsService()
    private let inboxService = InboxService()

    @State private var pendingFriendRequests: [FriendUser] = []
    @State private var watchlistInvites: [WatchlistInviteItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading inbox...")
                    .tint(Color("BrandSand"))
                    .foregroundStyle(Color("BrandSand"))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(Color("BrandRust"))
                        }

                        sectionTitle("Friend Requests")

                        if pendingFriendRequests.isEmpty {
                            emptyRow("No friend requests")
                        } else {
                            ForEach(pendingFriendRequests) { user in
                                friendRequestRow(user)
                            }
                        }

                        sectionTitle("Watchlist Invites")

                        if watchlistInvites.isEmpty {
                            emptyRow("No watchlist invites")
                        } else {
                            ForEach(watchlistInvites) { invite in
                                watchlistInviteRow(invite)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInbox()
        }
        .refreshable {
            await loadInbox()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color("BrandTeal"))
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.gray)
            .padding(.vertical, 4)
    }

    private func friendRequestRow(_ user: FriendUser) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.display_name)
                    .foregroundStyle(.white)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.gray)
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
        .padding(.vertical, 4)
    }

    private func watchlistInviteRow(_ invite: WatchlistInviteItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.watchlist_name)
                    .foregroundStyle(.white)

                Text("Invited by \(invite.invited_by_name)")
                    .font(.caption)
                    .foregroundStyle(.gray)
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
        .padding(.vertical, 4)
    }

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

            let friends = try await friendsResponse
            let invites = try await invitesResponse

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
