import SwiftUI

struct WatchlistMatchesView: View {
    @EnvironmentObject var authStore: AuthStore

    let watchlistId: Int
    let watchlistName: String

    private let watchlistService = WatchlistService()

    @State private var movies: [WatchlistMovie] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                headerView

                if isLoading {
                    Spacer()
                    ProgressView("Loading matches...")
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
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(movies) { movie in
                                movieCard(movie)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if movies.isEmpty {
                await loadMovies()
            }
        }
        .refreshable {
            await loadMovies()
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(watchlistName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Matched Movies")
                .font(.headline)
                .foregroundStyle(Color("BrandTeal"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 120)

            Text("No matches yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))

            Text("Once your group starts matching on movies, they’ll show up here.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func movieCard(_ movie: WatchlistMovie) -> some View {
        VStack(spacing: 14) {
            Group {
                if let posterURL = movie.posterURL {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.08))

                                ProgressView()
                                    .tint(Color("BrandSand"))
                            }

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

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
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(movie.title ?? "Untitled Movie")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("BrandSand"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func loadMovies() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        errorMessage = ""
        isLoading = true

        do {
            movies = try await watchlistService.fetchWatchlistMovies(
                token: token,
                watchlistId: watchlistId
            )
        } catch {
            print("WATCHLIST MOVIES LOAD ERROR:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        WatchlistMatchesView(
            watchlistId: 1,
            watchlistName: "Friday Night Picks"
        )
        .environmentObject(AuthStore())
    }
}
