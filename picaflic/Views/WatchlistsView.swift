import SwiftUI

struct WatchlistsView: View {
    @EnvironmentObject var authStore: AuthStore

    private let watchlistService = WatchlistService()
    private let friendsService = FriendsService()

    @State private var watchlists: [WatchlistSummary] = []
    @State private var acceptedFriends: [FriendUser] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showCreateSheet = false

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
                            VStack(alignment: .leading, spacing: 20) {
                                sectionTitle("Shared Watchlists")

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

                                sectionTitle("My Watchlists")

                                Text("Personal watchlists coming next.")
                                    .foregroundStyle(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .task {
                if watchlists.isEmpty {
                    await refreshAll()
                }
            }
            .refreshable {
                await refreshAll()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateWatchlistSheetView(
                    friends: acceptedFriends,
                    onCreated: {
                        await refreshAll()
                    }
                )
                .environmentObject(authStore)
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

                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color("BrandGold"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
                showCreateSheet = true
            } label: {
                Text("Create Watchlist")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("BrandGold"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color("BrandTeal"))
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

    private func refreshAll() async {
        await loadWatchlists()
        await loadAcceptedFriends()
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
            print("LOAD WATCHLISTS ERROR:", error)
        }

        isLoading = false
    }

    private func loadAcceptedFriends() async {
        guard let token = authStore.accessToken else { return }

        do {
            let response = try await friendsService.fetchFriends(token: token)
            acceptedFriends = response.friends
        } catch {
            print("LOAD FRIENDS FOR WATCHLIST ERROR:", error)
        }
    }
}

#Preview {
    WatchlistsView()
        .environmentObject(AuthStore())
}
