import SwiftUI

struct PersonalShareMatchesView: View {
    let shareId: Int
    let watchlistName: String

    private let service = PersonalWatchlistService()

    @EnvironmentObject var authStore: AuthStore
    @State private var movies: [FeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

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
        .navigationTitle("\(watchlistName) Matches")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMatches() }
        .refreshable { await loadMatches() }
    }

    private func movieCard(_ movie: FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            Text("No matches yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
            Text("Swipe right on something you'd both watch to make a match.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
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

    private func loadMatches() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        errorMessage = ""
        do {
            movies = try await service.fetchShareMatches(token: token, shareId: shareId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PersonalShareMatchesView(shareId: 1, watchlistName: "Date Night")
            .environmentObject(AuthStore())
    }
}
