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
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if items.isEmpty {
                    Text("No items found")
                        .padding()
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)

                            Text(item.isTV ? "TV" : "Movie")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Local ID: \(item.localId.map(String.init) ?? "nil")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
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

    private func loadFeed() async {
        errorMessage = ""
        isLoading = true

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }

        do {
            let results = try await feedService.fetchForYou(
                token: token,
                query: query
            )

            print("Loaded \(results.count) items")
            items = results
        } catch {
            print("Browse load error: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
