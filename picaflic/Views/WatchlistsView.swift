import SwiftUI

struct WatchlistsView: View {
    @EnvironmentObject var authStore: AuthStore

    private let watchlistService = WatchlistService()
    private let friendsService = FriendsService()
    private let personalService = PersonalWatchlistService()

    @State private var watchlists: [WatchlistSummary] = []
    @State private var personalWatchlists: [PersonalWatchlist] = []
    @State private var acceptedFriends: [FriendUser] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showCreateGroupSheet = false
    @State private var showCreatePersonalSheet = false
    @State private var newPersonalName = ""
    @State private var isCreatingPersonal = false
    @State private var showCreateMenu = false
    @State private var membersPopover: WatchlistSummary? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 0) {
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
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {

                                // MARK: - Personal Watchlists Block
                                VStack(spacing: 0) {
                                    // Block header
                                    HStack {
                                        Text("Your Watchlist")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color("BrandTeal"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14).corners([.topLeft, .topRight]))

                                    // Block content
                                    VStack(spacing: 0) {
                                        if personalWatchlists.isEmpty {
                                            Text("No personal watchlists yet. Tap + to create one.")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.5))
                                                .padding(16)
                                        } else {
                                            ForEach(personalWatchlists) { wl in
                                                NavigationLink {
                                                    PersonalWatchlistDetailView(watchlist: wl)
                                                        .environmentObject(authStore)
                                                } label: {
                                                    HStack(spacing: 10) {
                                                        Image("EyeballGraphic")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 20, height: 20)

                                                        Text(wl.name)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(Color("BrandGold"))

                                                        Spacer()

                                                        Image(systemName: "chevron.right")
                                                            .font(.caption)
                                                            .foregroundStyle(.white.opacity(0.3))
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 14)
                                                }
                                                .buttonStyle(.plain)

                                                if wl.id != personalWatchlists.last?.id {
                                                    Divider()
                                                        .background(Color.white.opacity(0.08))
                                                        .padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                    }
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 14).corners([.bottomLeft, .bottomRight]))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )

                                // MARK: - Group Watchlists Block
                                VStack(spacing: 0) {
                                    // Block header
                                    HStack {
                                        Text("Watch with Friends")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color("BrandTeal"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14).corners([.topLeft, .topRight]))

                                    // Block content
                                    VStack(spacing: 0) {
                                        if watchlists.isEmpty {
                                            Text("No group watchlists yet. Tap + to create one with friends.")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.5))
                                                .padding(16)
                                        } else {
                                            ForEach(watchlists) { watchlist in
                                                NavigationLink {
                                                    WatchlistDetailView(
                                                        watchlistId: watchlist.id,
                                                        watchlistName: watchlist.name
                                                    )
                                                } label: {
                                                    HStack(spacing: 10) {
                                                        Image("EyeballGraphic")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 20, height: 20)

                                                        Text(watchlist.name)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(Color("BrandGold"))
                                                            .lineLimit(1)

                                                        Spacer()

                                                        // Member count — long press to see names
                                                        Button {
                                                            membersPopover = watchlist
                                                        } label: {
                                                            Text(memberLabel(watchlist))
                                                                .font(.caption.weight(.semibold))
                                                                .foregroundStyle(Color("BrandGold"))
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .background(Color("BrandGold").opacity(0.15))
                                                                .clipShape(Capsule())
                                                        }
                                                        .buttonStyle(.plain)

                                                        Image(systemName: "chevron.right")
                                                            .font(.caption)
                                                            .foregroundStyle(.white.opacity(0.3))
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 14)
                                                }
                                                .buttonStyle(.plain)

                                                if watchlist.id != watchlists.last?.id {
                                                    Divider()
                                                        .background(Color.white.opacity(0.08))
                                                        .padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                    }
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 14).corners([.bottomLeft, .bottomRight]))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .task {
                if watchlists.isEmpty && personalWatchlists.isEmpty {
                    await refreshAll()
                }
            }
            .refreshable {
                await refreshAll()
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                CreateWatchlistSheetView(
                    friends: acceptedFriends,
                    onCreated: {
                        await refreshAll()
                    }
                )
                .environmentObject(authStore)
            }
            .sheet(isPresented: $showCreatePersonalSheet) {
                createPersonalWatchlistSheet
            }
            .alert(
                membersPopover?.name ?? "",
                isPresented: Binding(
                    get: { membersPopover != nil },
                    set: { if !$0 { membersPopover = nil } }
                )
            ) {
                Button("Done", role: .cancel) { membersPopover = nil }
            } message: {
                if let wl = membersPopover {
                    Text(wl.member_names.isEmpty
                         ? "No other members yet."
                         : wl.member_names.joined(separator: ", "))
                }
            }
        }
    }

    // MARK: - Header

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

                // + menu
                Menu {
                    Button {
                        showCreatePersonalSheet = true
                    } label: {
                        Label("New Personal Watchlist", systemImage: "person.fill")
                    }

                    Button {
                        showCreateGroupSheet = true
                    } label: {
                        Label("New Friends Watchlist", systemImage: "person.2.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color("BrandGold"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            Text("Select a watchlist to find a movie!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func memberLabel(_ wl: WatchlistSummary) -> String {
        if wl.member_names.isEmpty { return "" }
        if wl.member_names.count == 1 { return "@\(wl.member_names[0])" }
        return "@\(wl.member_names[0]), +\(wl.member_names.count - 1)"
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color("BrandTeal"))
    }

    // MARK: - Personal Watchlist Sheet

    private var createPersonalWatchlistSheet: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Watchlist name", text: $newPersonalName)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                    Button {
                        Task {
                            guard let token = authStore.accessToken else { return }
                            let name = newPersonalName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            isCreatingPersonal = true
                            do {
                                _ = try await personalService.createWatchlist(token: token, name: name)
                                newPersonalName = ""
                                showCreatePersonalSheet = false
                                await loadPersonalWatchlists()
                            } catch {
                                print("CREATE PERSONAL WATCHLIST ERROR:", error)
                            }
                            isCreatingPersonal = false
                        }
                    } label: {
                        Group {
                            if isCreatingPersonal {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Watchlist")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandGold"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(newPersonalName.trimmingCharacters(in: .whitespaces).isEmpty || isCreatingPersonal)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("New Personal Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCreatePersonalSheet = false }
                        .foregroundStyle(Color("BrandSand"))
                }
            }
        }
        .presentationDetents([.height(280)])
    }

    // MARK: - Personal Watchlist Card

    private func personalWatchlistCard(_ wl: PersonalWatchlist) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(wl.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
            HStack {
                Label("\(wl.movie_count) movies", systemImage: "film")
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

    // MARK: - Data

    private func refreshAll() async {
        isLoading = true
        await loadWatchlists()
        await loadPersonalWatchlists()
        await loadAcceptedFriends()
        isLoading = false
    }

    private func loadWatchlists() async {
        guard let token = authStore.accessToken else { return }
        do {
            watchlists = try await watchlistService.fetchWatchlists(token: token)
        } catch {
            errorMessage = error.localizedDescription
            print("LOAD WATCHLISTS ERROR:", error)
        }
    }

    private func loadPersonalWatchlists() async {
        guard let token = authStore.accessToken else { return }
        do {
            personalWatchlists = try await personalService.fetchWatchlists(token: token)
        } catch {
            print("LOAD PERSONAL WATCHLISTS ERROR:", error)
        }
    }

    private func loadAcceptedFriends() async {
        guard let token = authStore.accessToken else { return }
        do {
            let response = try await friendsService.fetchFriends(token: token)
            acceptedFriends = response.friends
        } catch {
            print("LOAD FRIENDS ERROR:", error)
        }
    }
}

#Preview {
    WatchlistsView()
        .environmentObject(AuthStore())
}
