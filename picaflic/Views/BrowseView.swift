import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var authStore: AuthStore

    private let feedService = FeedService()

    @State private var items: [FeedItem] = []
    @State private var query = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Browse")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Logout") {
                            authStore.clear()
                        }
                    }
                }
                .searchable(text: $query, prompt: "Search movies or shows")
                .onSubmit(of: .search) {
                    Task {
                        await loadFeed()
                    }
                }
                .task {
                    await loadFeed()
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            ProgressView()
        } else if !errorMessage.isEmpty {
            Text(errorMessage)
                .padding()
        } else {
            List(items) { item in
                BrowseRowView(item: item)
            }
        }
    }

    private func loadFeed() async {
        errorMessage = ""
        isLoading = true

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }

        do {
            items = try await feedService.fetchForYou(
                token: token,
                query: query
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

private struct BrowseRowView: View {
    let item: FeedItem

    var body: some View {
        HStack(spacing: 12) {
            posterView

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.isTV ? "TV" : "Movie")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let release = item.release_date, !release.isEmpty {
                    Text(release)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Local ID: \(item.localId.map(String.init) ?? "nil")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var posterView: some View {
        AsyncImage(url: item.posterURL) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .opacity(0.2)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            case .failure:
                Rectangle()
                    .opacity(0.2)

            @unknown default:
                Rectangle()
                    .opacity(0.2)
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
