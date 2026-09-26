import SwiftUI

struct PersonalWatchlistDetailView: View {
    let watchlist: PersonalWatchlist
    var onUpdated: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil

    private let service = PersonalWatchlistService()
    private let friendsService = FriendsService()

    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var movies: [FeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var movieToRemove: FeedItem? = nil
    @State private var showRemoveConfirm = false

    @State private var showShareSheet = false
    @State private var shareFriends: [FriendUser] = []
    @State private var isLoadingFriends = false
    @State private var sharingToUserId: Int? = nil
    @State private var shareFeedback = ""

    private enum ActiveSheet: Identifiable {
        case actions, rename, delete
        var id: Self { self }
    }

    @State private var activeSheet: ActiveSheet? = nil

    init(
        watchlist: PersonalWatchlist,
        onUpdated: (() -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self.watchlist = watchlist
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _displayName = State(initialValue: watchlist.name)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView("Loading...")
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
                } else if movies.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(movies) { movie in
                                movieCard(movie)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMovies() }
        .refreshable { await loadMovies() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .actions
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .sheet(item: $activeSheet) { kind in
            switch kind {
            case .actions:
                BrandActionSheet(
                    title: displayName,
                    options: [
                        BrandActionSheetOption(title: "Share", systemImage: "square.and.arrow.up") {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showShareSheet = true
                                Task { await loadShareFriends() }
                            }
                        },
                        BrandActionSheetOption(title: "Rename", systemImage: "pencil") {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeSheet = .rename
                            }
                        },
                        BrandActionSheetOption(title: "Delete Watchlist", systemImage: "trash", isDestructive: true) {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeSheet = .delete
                            }
                        },
                    ],
                    onCancel: { activeSheet = nil }
                )
            case .rename:
                BrandRenameSheet(
                    title: "Rename Watchlist",
                    name: displayName,
                    onCancel: { activeSheet = nil },
                    onSave: { newName in
                        activeSheet = nil
                        Task { await renameWatchlist(to: newName) }
                    }
                )
            case .delete:
                BrandConfirmDialog(
                    title: "Delete Watchlist?",
                    message: "This deletes \"\(displayName)\" and everything in it. This can't be undone.",
                    confirmTitle: "Delete",
                    onCancel: { activeSheet = nil },
                    onConfirm: {
                        activeSheet = nil
                        Task { await deleteWatchlist() }
                    }
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            shareSheet
        }
        .confirmationDialog(
            "Remove from watchlist?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let movie = movieToRemove {
                    Task { await removeMovie(movie) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let movie = movieToRemove {
                Text("Remove \"\(movie.title)\" from \(displayName)?")
            }
        }
    }

    // MARK: - Movie Card

    private func movieCard(_ movie: FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let posterURL = movie.posterURL {
                        AsyncImage(url: posterURL) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.08))
                                    ProgressView().tint(Color("BrandSand"))
                                }
                            case .success(let image):
                                image.resizable().aspectRatio(2/3, contentMode: .fill)
                            case .failure:
                                VHSMoviePlaceholderView()
                            @unknown default:
                                VHSMoviePlaceholderView()
                            }
                        }
                    } else {
                        VHSMoviePlaceholderView()
                    }
                }
                .aspectRatio(2/3, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Service badge
                if !movie.providers.isEmpty {
                    ProviderIconStack(providers: movie.providers)
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    tagView(movie.isTV ? "TV" : "Movie")
                    if let year = formattedYear(from: movie.release_date) {
                        tagView(year)
                    }
                }

                // Remove button
                Button {
                    movieToRemove = movie
                    showRemoveConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Remove")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color("BrandRust"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("BrandRust").opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            Text("No movies yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
            Text("Browse the home feed and bookmark movies to add them here.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoadingFriends {
                        Spacer()
                        ProgressView().tint(Color("BrandSand"))
                        Spacer()
                    } else if shareFriends.isEmpty {
                        Spacer()
                        Text("Add some friends first to share this watchlist.")
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        List(shareFriends, id: \.id) { friend in
                            Button {
                                Task { await share(with: friend) }
                            } label: {
                                HStack {
                                    Text(friend.display_name)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if sharingToUserId == friend.id {
                                        ProgressView().tint(Color("BrandSand"))
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        .scrollContentBackground(.hidden)
                    }

                    if !shareFeedback.isEmpty {
                        Text(shareFeedback)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("BrandGold"))
                            .padding()
                    }
                }
            }
            .navigationTitle("Share \"\(displayName)\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { showShareSheet = false }
                        .foregroundStyle(Color("BrandSand"))
                }
            }
        }
    }

    // MARK: - Helpers

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color("BrandGold"))
            .clipShape(Capsule())
    }

    private func formattedYear(from releaseDate: String?) -> String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    // MARK: - Data

    private func loadMovies() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        errorMessage = ""
        do {
            let response: FeedResultsResponse = try await APIClient.shared.request(
                path: "/personal-watchlists/\(watchlist.id)/movies",
                token: token
            )
            movies = response.results
        } catch {
            errorMessage = error.localizedDescription
            print("PERSONAL WATCHLIST MOVIES ERROR:", error)
        }
        isLoading = false
    }

    private func removeMovie(_ movie: FeedItem) async {
        guard let token = authStore.accessToken,
              let movieId = movie.localId else { return }
        do {
            try await service.removeMovie(
                token: token,
                watchlistId: watchlist.id,
                movieId: movieId
            )
            movies.removeAll { $0.id == movie.id }
        } catch {
            print("REMOVE MOVIE ERROR:", error)
        }
    }

    private func renameWatchlist(to newName: String) async {
        guard let token = authStore.accessToken else { return }
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            try await service.renameWatchlist(token: token, watchlistId: watchlist.id, name: name)
            displayName = name
            onUpdated?()
        } catch {
            print("RENAME PERSONAL WATCHLIST ERROR:", error)
        }
    }

    private func deleteWatchlist() async {
        guard let token = authStore.accessToken else { return }
        do {
            try await service.deleteWatchlist(token: token, watchlistId: watchlist.id)
            onDeleted?()
            dismiss()
        } catch {
            print("DELETE PERSONAL WATCHLIST ERROR:", error)
        }
    }

    private func loadShareFriends() async {
        guard let token = authStore.accessToken else { return }
        isLoadingFriends = true
        do {
            let response = try await friendsService.fetchFriends(token: token)
            shareFriends = response.friends
        } catch {
            print("LOAD SHARE FRIENDS ERROR:", error)
        }
        isLoadingFriends = false
    }

    private func share(with friend: FriendUser) async {
        guard let token = authStore.accessToken else { return }
        sharingToUserId = friend.id
        do {
            _ = try await service.shareWatchlist(token: token, watchlistId: watchlist.id, friendUserId: friend.id)
            shareFeedback = "Sent to \(friend.display_name)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showShareSheet = false
                shareFeedback = ""
            }
        } catch {
            shareFeedback = "Couldn't share — try again."
            print("SHARE WATCHLIST ERROR:", error)
        }
        sharingToUserId = nil
    }
}

#Preview {
    NavigationStack {
        PersonalWatchlistDetailView(
            watchlist: PersonalWatchlist(id: 1, name: "My Favourites", movie_count: 3)
        )
        .environmentObject(AuthStore())
    }
}
