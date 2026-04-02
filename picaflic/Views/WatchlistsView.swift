import SwiftUI

struct WatchlistsView: View {
    @EnvironmentObject var authStore: AuthStore

    private let watchlistService = WatchlistService()

    @State private var watchlists: [WatchlistSummary] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    headerView

                    if isLoading {
                        Spacer()
                        ProgressView("Loading watchlists...")
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
                    } else if watchlists.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(watchlists) { watchlist in
                                    NavigationLink {
                                        WatchlistDetailView(
                                            watchlistId: watchlist.id,
                                            watchlistName: watchlist.name
                                        )
                                    } label: {
                                        watchlistCard(watchlist)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .task {
                if watchlists.isEmpty {
                    await loadWatchlists()
                }
            }
            .refreshable {
                await loadWatchlists()
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
                Text("Watchlists")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color("BrandSand"))

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("No watchlists yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))

            Text("Create a watchlist with friends to start matching on movies together.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                // placeholder for create watchlist flow
            } label: {
                Text("Create Watchlist")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("BrandGold"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func watchlistCard(_ watchlist: WatchlistSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(watchlist.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
                .multilineTextAlignment(.leading)

            HStack(spacing: 10) {
                Label("\(watchlist.member_count) members", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color("BrandTeal"))

                Spacer()

                Text("Open")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGold"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func loadWatchlists() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        errorMessage = ""
        isLoading = true

        do {
            watchlists = try await watchlistService.fetchWatchlists(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    WatchlistsView()
        .environmentObject(AuthStore())
}
