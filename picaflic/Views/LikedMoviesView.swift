import SwiftUI

struct LikedMoviesView: View {
    @EnvironmentObject var authStore: AuthStore

    private let preferenceService = PreferenceService()

    @State private var movies: [LikedMovie] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var selectedMovieForDetail: FeedItem? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            if isLoading {
                ProgressView("Loading liked movies...")
                    .tint(Color("BrandSand"))
                    .foregroundStyle(Color("BrandSand"))
            } else if !errorMessage.isEmpty {
                VStack(spacing: 16) {
                    Text(errorMessage)
                        .foregroundStyle(Color("BrandRust"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button("Try Again") {
                        Task { await load() }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color("BrandTeal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else if movies.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(movies) { movie in
                            movieCard(movie)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Liked Movies")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $selectedMovieForDetail) { movie in
            if let token = authStore.accessToken {
                MovieDetailSheet(movie: movie, token: token)
            }
        }
    }

    // MARK: - Card

    private func movieCard(_ movie: LikedMovie) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                posterImage(for: movie)
                    .onTapGesture {
                        selectedMovieForDetail = asFeedItem(movie)
                    }

                Button {
                    Task { await unlike(movie) }
                } label: {
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color("BrandRust"))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color("BrandGold"))
                    }
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }

            Text(movie.title ?? "Untitled")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
                .lineLimit(2)
                .frame(height: 30, alignment: .top)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func posterImage(for movie: LikedMovie) -> some View {
        Group {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08))
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            Text("No liked movies yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
            Text("Tap the heart on any movie to save it here.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }

    // MARK: - Data

    private func load() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            movies = try await preferenceService.fetchLikedMovies(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func unlike(_ movie: LikedMovie) async {
        guard let token = authStore.accessToken else { return }
        do {
            _ = try await preferenceService.setPreference(token: token, movieId: movie.id, status: "none")
            movies.removeAll { $0.id == movie.id }
        } catch {
            print("UNLIKE ERROR:", error)
        }
    }

    /// Builds a minimal FeedItem from a LikedMovie so we can reuse MovieDetailSheet.
    private func asFeedItem(_ movie: LikedMovie) -> FeedItem {
        FeedItem(
            id: movie.id,
            tmdb_id: movie.tmdb_id ?? 0,
            is_tv: 0,
            title: movie.title ?? "",
            popularity: nil,
            release_date: nil,
            poster_path: movie.poster_path,
            provider_ids: nil,
            provider_names: nil,
            genre_ids: nil
        )
    }
}

#Preview {
    NavigationStack {
        LikedMoviesView()
            .environmentObject(AuthStore())
    }
}
