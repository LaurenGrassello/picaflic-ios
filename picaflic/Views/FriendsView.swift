import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authStore: AuthStore

    private let service = FriendsService()

    @State private var friends: [FriendUser] = []
    @State private var pendingReceived: [FriendUser] = []
    @State private var pendingSent: [FriendUser] = []
    @State private var searchResults: [UserSearchResult] = []
    @State private var query = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    headerView

                    searchBar

                    if isLoading {
                        Spacer()
                        ProgressView("Loading friends...")
                            .tint(Color("BrandSand"))
                            .foregroundStyle(Color("BrandSand"))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .foregroundStyle(Color("BrandRust"))
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }

                                if !pendingReceived.isEmpty {
                                    sectionTitle("Friend Requests")

                                    ForEach(pendingReceived) { user in
                                        pendingRequestRow(user)
                                    }
                                }

                                if !pendingSent.isEmpty {
                                    sectionTitle("Pending Sent")

                                    ForEach(pendingSent) { user in
                                        sentRequestRow(user)
                                    }
                                }

                                if !searchResults.isEmpty {
                                    sectionTitle("Search Results")

                                    ForEach(searchResults) { user in
                                        searchResultRow(user)
                                    }
                                }

                                sectionTitle("Your Friends")

                                if friends.isEmpty {
                                    Text("No friends yet")
                                        .foregroundStyle(.gray)
                                } else {
                                    ForEach(friends) { friend in
                                        friendRow(friend)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding()
            }
            .task {
                await loadFriends()
            }
            .refreshable {
                await loadFriends()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            HStack {
                Text("Friends")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color("BrandSand"))

                Spacer()
            }
        }
    }

    private var searchBar: some View {
        TextField("Search users...", text: $query)
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            .submitLabel(.search)
            .onSubmit {
                Task { await search() }
            }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color("BrandTeal"))
    }

    private func friendRow(_ friend: FriendUser) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.display_name)
                    .foregroundStyle(.white)

                Text(friend.email)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text("Friends")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("BrandTeal"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func pendingRequestRow(_ user: FriendUser) -> some View {
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
                Task { await accept(user) }
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
                Task { await decline(user) }
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

    private func sentRequestRow(_ user: FriendUser) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.display_name)
                    .foregroundStyle(.white)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text("Pending")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("BrandGold"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func searchResultRow(_ user: UserSearchResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.display_name)
                    .foregroundStyle(.white)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if user.friendship_status == "accepted" {
                Text("Friends")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("BrandTeal"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            } else if user.friendship_status == "pending" || user.friendship_status == "pending_sent" {
                Text("Pending")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            } else {
                Button {
                    Task { await add(user) }
                } label: {
                    Text("Add")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("BrandTeal"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func loadFriends() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let response = try await service.fetchFriends(token: token)
            friends = response.friends
            pendingReceived = response.pending_received
            pendingSent = response.pending_sent
        } catch {
            errorMessage = error.localizedDescription
            print("LOAD FRIENDS ERROR:", error)
        }

        isLoading = false
    }

    private func search() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        do {
            searchResults = try await service.searchUsers(token: token, query: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            print("SEARCH USERS ERROR:", error)
        }
    }

    private func add(_ user: UserSearchResult) async {
        guard let token = authStore.accessToken else { return }

        do {
            try await service.sendFriendRequest(token: token, userId: user.id)

            if let index = searchResults.firstIndex(where: { $0.id == user.id }) {
                let updated = UserSearchResult(
                    id: user.id,
                    display_name: user.display_name,
                    email: user.email,
                    friendship_status: "pending"
                )
                searchResults[index] = updated
            }

            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
            print("SEND FRIEND REQUEST ERROR:", error)
        }
    }

    private func accept(_ user: FriendUser) async {
        guard let token = authStore.accessToken else { return }

        do {
            try await service.acceptFriend(token: token, userId: user.id)
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
            print("ACCEPT FRIEND ERROR:", error)
        }
    }

    private func decline(_ user: FriendUser) async {
        guard let token = authStore.accessToken else { return }

        do {
            try await service.declineFriend(token: token, userId: user.id)
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
            print("DECLINE FRIEND ERROR:", error)
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthStore())
}
