import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authStore: AuthStore

    private let homeService = HomeService()
    private let preferenceService = PreferenceService()

    @State private var movies: [FeedItem] = []
    @State private var likedIds: Set<Int> = []
    @State private var dislikedIds: Set<Int> = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    headerView
                    searchBar
                    filterRow

                    if isLoading {
                        Spacer()
                        ProgressView("Loading movies...")
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
                                ForEach(filteredMovies) { movie in
                                    movieCard(movie)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .task {
                if movies.isEmpty {
                    await loadHome()
                }
            }
            .refreshable {
                await loadHome()
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
                Text("Pic-a-Flic")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color("BrandSand"))

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("BrandSand").opacity(0.8))

            TextField("Search movies or shows", text: $searchText)
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit {
                    Task { await runSearch() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadHome() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("BrandSand").opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterPill("All Services", active: true)
                filterPill("Genre", active: false)
                filterPill("Movies", active: false)
                filterPill("TV", active: false)
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterPill(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(active ? .white : Color("BrandSand"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(active ? Color("BrandTeal") : Color.white.opacity(0.06))
            .clipShape(Capsule())
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 120)

            Text("No movies found")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))

            Text("Try another search or refresh your feed.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var filteredMovies: [FeedItem] {
        movies.filter { movie in
            guard let id = movie.localId else { return true }
            return !dislikedIds.contains(id)
        }
    }

    private func movieCard(_ movie: FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 18))

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

                HStack(spacing: 12) {
                    Button {
                        Task { await likeMovie(movie) }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(likeColor(for: movie))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await dislikeMovie(movie) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(dislikeColor(for: movie))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
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

    private func likeColor(for movie: FeedItem) -> Color {
        guard let id = movie.localId else { return Color("BrandGold") }
        return likedIds.contains(id) ? Color("BrandTeal") : Color("BrandGold")
    }

    private func dislikeColor(for movie: FeedItem) -> Color {
        guard let id = movie.localId else { return Color("BrandRust") }
        return dislikedIds.contains(id) ? Color("BrandTeal") : Color("BrandRust")
    }

    private func loadHome() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            movies = try await homeService.fetchHomeFeed(token: token)
        } catch {
            errorMessage = error.localizedDescription
            print("HOME LOAD ERROR:", error)
        }

        isLoading = false
    }

    private func runSearch() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await loadHome()
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            movies = try await homeService.searchMovies(token: token, query: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            print("HOME SEARCH ERROR:", error)
        }

        isLoading = false
    }

    private func likeMovie(_ movie: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = movie.localId else { return }

        do {
            _ = try await preferenceService.setPreference(
                token: token,
                movieId: localId,
                status: "liked"
            )
            likedIds.insert(localId)
            dislikedIds.remove(localId)
        } catch {
            print("LIKE MOVIE ERROR:", error)
        }
    }

    private func dislikeMovie(_ movie: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = movie.localId else { return }

        do {
            _ = try await preferenceService.setPreference(
                token: token,
                movieId: localId,
                status: "disliked"
            )
            dislikedIds.insert(localId)
            likedIds.remove(localId)
        } catch {
            print("DISLIKE MOVIE ERROR:", error)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthStore())
}
