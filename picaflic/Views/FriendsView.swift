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
    @State private var messageRecipient: FriendUser? = nil
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

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
                        VStack(spacing: 12) {
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundStyle(Color("BrandRust"))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.horizontal, 16)
                            }

                            // Search results
                            if !searchResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(searchResults) { user in
                                        searchResultRow(user)
                                        if user.id != searchResults.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.08))
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(Color("BrandGold").opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color("BrandGold").opacity(0.4), lineWidth: 1)
                                )
                            }

                            // Friends + pending list block
                            VStack(spacing: 0) {
                                // Header row
                                HStack {
                                    Text("Friends")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Username")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("+/-")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, alignment: .center)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color("BrandTeal"))

                                // Pending received
                                ForEach(pendingReceived) { user in
                                    friendListRow(
                                        name: user.display_name,
                                        username: "@\(user.display_name)",
                                        status: .pendingReceived,
                                        onPlus: { Task { await accept(user) } },
                                        onMinus: { Task { await decline(user) } }
                                    )
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.horizontal, 16)
                                }

                                // Pending sent
                                ForEach(pendingSent) { user in
                                    friendListRow(
                                        name: user.display_name,
                                        username: "@\(user.display_name)",
                                        status: .pendingSent,
                                        onPlus: nil,
                                        onMinus: { Task { await decline(user) } }
                                    )
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.horizontal, 16)
                                }

                                // Accepted friends
                                if friends.isEmpty && pendingReceived.isEmpty && pendingSent.isEmpty {
                                    Text("No friends yet — search above to add some!")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                        .padding(24)
                                } else {
                                    ForEach(friends) { friend in
                                        NavigationLink {
                                            FriendProfileView(
                                                friend: friend,
                                                token: authStore.accessToken ?? "",
                                                onSendMessage: { recipient in
                                                    messageRecipient = recipient
                                                }
                                            )
                                            .environmentObject(authStore)
                                        } label: {
                                            friendListRow(
                                                name: friend.display_name,
                                                username: "@\(friend.display_name)",
                                                status: .accepted,
                                                onPlus: nil,
                                                onMinus: nil
                                            )
                                        }
                                        .buttonStyle(.plain)

                                        if friend.id != friends.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.08))
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .task { await loadFriends() }
        .refreshable { await loadFriends() }
        .sheet(item: $messageRecipient) { friend in
            MessageComposeView(
                recipient: friend,
                token: authStore.accessToken ?? ""
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image("Friends_Avatars")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 16)

            Text("Add your friends. Share watchlists and\nhelp each other \"pic\" something to watch!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                TextField("Search", text: $query)
                    .foregroundStyle(.white)
                    .font(.title3.weight(.semibold))
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await search() }
                    }

                Button {
                    Task { await search() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("BrandGold"))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)

            Text("Find friends by username or email.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Friend List Row

    private enum FriendRowStatus {
        case accepted, pendingReceived, pendingSent
    }

    private func friendListRow(
        name: String,
        username: String,
        status: FriendRowStatus,
        onPlus: (() -> Void)?,
        onMinus: (() -> Void)?
    ) -> some View {
        HStack {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(status == .pendingReceived ? Color("BrandGold") : .white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(username)
                .font(.subheadline)
                .foregroundStyle(status == .pendingReceived ? Color("BrandGold") : .white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                switch status {
                case .accepted:
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 44)

                case .pendingReceived:
                    Button {
                        onPlus?()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color("BrandGold"))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onMinus?()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color("BrandRust"))
                    }
                    .buttonStyle(.plain)

                case .pendingSent:
                    Button {
                        onMinus?()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color("BrandRust").opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(status == .pendingReceived ? Color("BrandGold").opacity(0.08) : Color.clear)
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ user: UserSearchResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(user.display_name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if user.friendship_status == "accepted" {
                Text("Friends")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("BrandTeal"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("BrandTeal").opacity(0.15))
                    .clipShape(Capsule())
            } else if user.friendship_status == "pending" || user.friendship_status == "pending_sent" {
                Text("Pending")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("BrandGold").opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Button {
                    Task { await add(user) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color("BrandGold"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
                searchResults[index] = UserSearchResult(
                    id: user.id,
                    display_name: user.display_name,
                    email: user.email,
                    friendship_status: "pending"
                )
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
    NavigationStack {
        FriendsView()
            .environmentObject(AuthStore())
    }
}
