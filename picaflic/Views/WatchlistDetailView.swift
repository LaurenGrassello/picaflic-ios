import SwiftUI

struct WatchlistDetailView: View {
    let watchlistId: Int
    let createdBy: Int
    var onUpdated: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil

    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    private let watchlistService = WatchlistService()

    @State private var displayName: String
    @State private var errorMessage = ""

    private enum ActiveSheet: Identifiable {
        case actions, rename, delete
        var id: Self { self }
    }

    @State private var activeSheet: ActiveSheet? = nil

    init(
        watchlistId: Int,
        watchlistName: String,
        createdBy: Int,
        onUpdated: (() -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self.watchlistId = watchlistId
        self.createdBy = createdBy
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _displayName = State(initialValue: watchlistName)
    }

    private var isOwner: Bool {
        authStore.currentUser?.id == createdBy
    }

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)

                Text(displayName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .multilineTextAlignment(.center)

                Text("Choose what you want to do in this watchlist.")
                    .foregroundStyle(Color("BrandSand").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color("BrandRust"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                NavigationLink {
                    SwipeView(
                        watchlistId: watchlistId,
                        watchlistName: displayName
                    )
                } label: {
                    Text("Start Swiping")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandGold"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                NavigationLink {
                    WatchlistMatchesView(
                        watchlistId: watchlistId,
                        watchlistName: displayName
                    )
                } label: {
                    Text("View Matches")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color("BrandGold"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandGold").opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("BrandGold").opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .actions
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("BrandSand"))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { kind in
            switch kind {
            case .actions:
                BrandActionSheet(
                    title: displayName,
                    options: [
                        BrandActionSheetOption(title: "Rename", systemImage: "pencil") {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeSheet = .rename
                            }
                        },
                        BrandActionSheetOption(title: "Delete Watchlist", systemImage: "trash", isDestructive: true) {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeSheet = .delete
                            }
                        },
                    ],
                    onCancel: { activeSheet = nil }
                )
            case .rename:
                BrandRenameSheet(
                    title: "Rename Watchlist",
                    name: displayName,
                    onCancel: { activeSheet = nil },
                    onSave: { newName in
                        activeSheet = nil
                        Task { await rename(to: newName) }
                    }
                )
            case .delete:
                BrandConfirmDialog(
                    title: "Delete Watchlist?",
                    message: "This removes \"\(displayName)\" for everyone in it. This can't be undone.",
                    confirmTitle: "Delete",
                    onCancel: { activeSheet = nil },
                    onConfirm: {
                        activeSheet = nil
                        Task { await delete() }
                    }
                )
            }
        }
    }

    // MARK: - Data

    private func rename(to newName: String) async {
        guard let token = authStore.accessToken else { return }
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            try await watchlistService.renameWatchlist(token: token, watchlistId: watchlistId, name: name)
            displayName = name
            onUpdated?()
        } catch {
            errorMessage = "Couldn't rename — try again."
            print("RENAME WATCHLIST ERROR:", error)
        }
    }

    private func delete() async {
        guard let token = authStore.accessToken else { return }
        do {
            try await watchlistService.deleteWatchlist(token: token, watchlistId: watchlistId)
            onDeleted?()
            dismiss()
        } catch {
            errorMessage = "Couldn't delete — try again."
            print("DELETE WATCHLIST ERROR:", error)
        }
    }
}

#Preview {
    NavigationStack {
        WatchlistDetailView(watchlistId: 1, watchlistName: "Friday Night Picks", createdBy: 1)
    }
    .environmentObject(AuthStore())
}
