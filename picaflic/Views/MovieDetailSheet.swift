import SwiftUI

struct MovieDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let movie: FeedItem
    let token: String

    @State private var details: MovieDetails?
    @State private var isLoadingDetails = false

    private let homeService = HomeService()

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    posterSection

                    VStack(alignment: .leading, spacing: 16) {
                        Text(movie.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("BrandSand"))

                        HStack(spacing: 8) {
                            tagView(movie.isTV ? "TV Show" : "Movie")
                            if let year = formattedYear(from: movie.release_date) {
                                tagView(year)
                            }
                            if let runtime = details?.runtime, runtime > 0 {
                                tagView("\(runtime) min")
                            }
                        }

                        if !movie.genreNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(movie.genreNames, id: \.self) { genre in
                                        Text(genre)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("BrandTeal"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white.opacity(0.9))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Divider().overlay(.white.opacity(0.15))

                        if !movie.providers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Available On")
                                    .font(.headline)
                                    .foregroundStyle(Color("BrandSand"))

                                VStack(spacing: 8) {
                                    ForEach(movie.providers, id: \.id) { provider in
                                        HStack(spacing: 10) {
                                            if let asset = provider.asset {
                                                Image(asset)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 28, height: 28)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                            Text(provider.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                        }
                                    }
                                }
                            }

                            Divider().overlay(.white.opacity(0.15))
                        }

                        if isLoadingDetails {
                            HStack {
                                ProgressView().tint(Color("BrandSand"))
                                Text("Loading details...")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        } else if let overview = details?.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .task {
            await fetchDetails()
        }
    }

    // MARK: - Poster

    private var posterSection: some View {
        Group {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.white.opacity(0.08)
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
    }

    // MARK: - Helpers

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color("BrandGold"))
            .clipShape(Capsule())
    }

    private func formattedYear(from releaseDate: String?) -> String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    private func fetchDetails() async {
        isLoadingDetails = true
        do {
            details = try await homeService.fetchDetails(
                token: token,
                tmdbId: movie.tmdb_id,
                isTV: movie.isTV
            )
        } catch {
            print("MOVIE DETAIL FETCH ERROR:", error)
        }
        isLoadingDetails = false
    }
}
