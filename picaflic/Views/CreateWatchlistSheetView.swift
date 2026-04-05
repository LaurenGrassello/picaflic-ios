import SwiftUI

struct CreateWatchlistSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    let friends: [FriendUser]
    let onCreated: () async -> Void

    private let watchlistService = WatchlistService()

    @State private var name = ""
    @State private var selectedFriendIds: Set<Int> = []
    @State private var isSubmitting = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Create Shared Watchlist")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("BrandSand"))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Watchlist Name")
                                .font(.headline)
                                .foregroundStyle(Color("BrandTeal"))

                            TextField("Friday Night Picks", text: $name)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Friends")
                                .font(.headline)
                                .foregroundStyle(Color("BrandTeal"))

                            Text("Choose at least 1 friend. Max 4 friends for now.")
                                .font(.caption)
                                .foregroundStyle(Color("BrandSand").opacity(0.8))
                        }

                        if friends.isEmpty {
                            Text("You need at least one accepted friend before creating a shared watchlist.")
                                .foregroundStyle(.gray)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(friends) { friend in
                                    friendSelectionRow(friend)
                                }
                            }
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(Color("BrandRust"))
                        }

                        Button {
                            Task {
                                await createWatchlist()
                            }
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("BrandGold"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                Text("Create Watchlist")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(canSubmit ? Color("BrandGold") : Color.gray.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit || isSubmitting)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color("BrandSand"))
                }
            }
        }
    }

    private var canSubmit: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !selectedFriendIds.isEmpty && selectedFriendIds.count <= 4
    }

    private func friendSelectionRow(_ friend: FriendUser) -> some View {
        Button {
            toggleSelection(for: friend.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.display_name)
                        .foregroundStyle(.white)

                    Text(friend.email)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if selectedFriendIds.contains(friend.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("BrandTeal"))
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(Color("BrandSand").opacity(0.7))
                        .font(.title3)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func toggleSelection(for id: Int) {
        if selectedFriendIds.contains(id) {
            selectedFriendIds.remove(id)
        } else {
            guard selectedFriendIds.count < 4 else { return }
            selectedFriendIds.insert(id)
        }
    }

    private func createWatchlist() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name."
            return
        }

        guard !selectedFriendIds.isEmpty else {
            errorMessage = "Please select at least one friend."
            return
        }

        isSubmitting = true
        errorMessage = ""

        do {
            _ = try await watchlistService.createWatchlist(
                token: token,
                name: trimmedName,
                memberIds: Array(selectedFriendIds)
            )

            await onCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("CREATE WATCHLIST ERROR:", error)
        }

        isSubmitting = false
    }
}

#Preview {
    CreateWatchlistSheetView(
        friends: [
            FriendUser(id: 1, display_name: "Alex", email: "alex@test.com"),
            FriendUser(id: 2, display_name: "Jordan", email: "jordan@test.com")
        ],
        onCreated: { }
    )
    .environmentObject(AuthStore())
}
