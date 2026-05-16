import SwiftUI

struct FriendProfileView: View {
    let friend: FriendUser
    let token: String

    private let watchlistService = WatchlistService()
    private let friendsService = FriendsService()

    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var sharedWatchlists: [WatchlistSummary] = []
    @State private var isLoading = false
    @State private var showMessageSheet = false
    @State private var showUnfriendAlert = false
    @State private var showCreateWatchlistSheet = false
    @State private var errorMessage = ""

    // Alternate avatar by friend ID
    private var avatarAsset: String {
        friend.id % 2 == 0 ? "YellowFriend" : "RedFriend"
    }

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Avatar + name
                    VStack(spacing: 12) {
                        Image(avatarAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)

                        Text(friend.display_name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("BrandSand"))

                        Text(friend.email)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 16)

                    // Shared Watchlists
                    VStack(spacing: 0) {
                        HStack {
                            Text("Shared Watchlists")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color("BrandTeal"))

                        VStack(spacing: 0) {
                            if isLoading {
                                ProgressView()
                                    .tint(Color("BrandSand"))
                                    .padding(16)
                            } else if sharedWatchlists.isEmpty {
                                Text("No shared watchlists yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(16)
                            } else {
                                ForEach(sharedWatchlists) { wl in
                                    HStack(spacing: 10) {
                                        Image("EyeballGraphic")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)

                                        Text(wl.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color("BrandGold"))

                                        Spacer()

                                        Text("\(wl.member_count) members")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)

                                    if wl.id != sharedWatchlists.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.08))
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                        .background(Color.white.opacity(0.05))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Actions
                    VStack(spacing: 12) {
                        // Send message
                        Button {
                            showMessageSheet = true
                        } label: {
                            HStack {
                                Image("Message_V2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Send a Message")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        // Create watchlist with friend
                        Button {
                            showCreateWatchlistSheet = true
                        } label: {
                            HStack {
                                Image("Friends_Avatars")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Create Watchlist Together")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        // Unfriend
                        Button {
                            showUnfriendAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundStyle(Color("BrandRust"))
                                Text("Unfriend")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("BrandRust"))
                                Spacer()
                            }
                            .padding(16)
                            .background(Color("BrandRust").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color("BrandRust"))
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(friend.display_name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSharedWatchlists() }
        .sheet(isPresented: $showMessageSheet) {
            MessageComposeView(
                recipient: friend,
                token: token,
                onDismiss: { showMessageSheet = false }
            )
        }
        .sheet(isPresented: $showCreateWatchlistSheet) {
            CreateWatchlistSheetView(
                friends: [friend],
                onCreated: {
                    showCreateWatchlistSheet = false
                    await loadSharedWatchlists()
                }
            )
            .environmentObject(authStore)
        }
        .alert("Unfriend \(friend.display_name)?", isPresented: $showUnfriendAlert) {
            Button("Unfriend", role: .destructive) {
                Task { await unfriend() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(friend.display_name) from your friends list.")
        }
    }

    private func loadSharedWatchlists() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        do {
            let all = try await watchlistService.fetchWatchlists(token: token)
            sharedWatchlists = all.filter { wl in
                wl.member_names.contains(friend.display_name)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func unfriend() async {
        guard let token = authStore.accessToken else { return }
        do {
            try await friendsService.declineFriend(token: token, userId: friend.id)
            dismiss()
        } catch {
            errorMessage = "Couldn't unfriend."
        }
    }
}
