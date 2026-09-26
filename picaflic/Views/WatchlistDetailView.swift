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
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    @State private var errorMessage = ""

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
                    Menu {
                        Button {
                            renameText = displayName
                            showRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Watchlist", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color("BrandSand"))
                    }
                }
            }
        }
        .alert("Rename Watchlist", isPresented: $showRenameAlert) {
            TextField("Watchlist name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task { await rename() }
            }
        }
        .confirmationDialog(
            "Delete this watchlist?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await delete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \"\(displayName)\" for everyone in it. This can't be undone.")
        }
    }

    private func rename() async {
        guard let token = authStore.accessToken else { return }
        let name = renameText.trimmingCharacters(in: .whitespaces)
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
