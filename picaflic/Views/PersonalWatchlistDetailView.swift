import SwiftUI

struct PersonalWatchlistDetailView: View {
    let watchlist: PersonalWatchlist

    private let service = PersonalWatchlistService()

    @EnvironmentObject var authStore: AuthStore
    @State private var movies: [FeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var movieToRemove: FeedItem? = nil
    @State private var showRemoveConfirm = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                        LazyVGrid(columns: columns, spacing: 18) {
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
        .navigationTitle(watchlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMovies() }
        .refreshable { await loadMovies() }
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
                Text("Remove \"\(movie.title)\" from \(watchlist.name)?")
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
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.08))
                                    ProgressView().tint(Color("BrandSand"))
                                }
                            case .success(let image):
                                image.resizable().scaledToFill()
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
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Service badge
                if let asset = movie.providerAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                        .padding(8)
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
}

#Preview {
    NavigationStack {
        PersonalWatchlistDetailView(
            watchlist: PersonalWatchlist(id: 1, name: "My Favourites", movie_count: 3)
        )
        .environmentObject(AuthStore())
    }
}
