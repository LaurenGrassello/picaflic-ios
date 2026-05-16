import SwiftUI

struct AddToWatchlistSheet: View {
    let movie: FeedItem
    let token: String
    var onDismiss: () -> Void

    private let service = PersonalWatchlistService()

    @State private var watchlists: [PersonalWatchlist] = []
    @State private var isLoading = true
    @State private var showNewWatchlistField = false
    @State private var newWatchlistName = ""
    @State private var isCreating = false
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Movie context header
                    HStack(spacing: 14) {
                        if let url = movie.posterURL {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color.white.opacity(0.08)
                                }
                            }
                            .frame(width: 48, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add to Watchlist")
                                .font(.headline)
                                .foregroundStyle(Color("BrandSand"))
                            Text(movie.title)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.04))

                    if let success = successMessage {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color("BrandTeal"))
                            Text(success)
                                .font(.headline)
                                .foregroundStyle(Color("BrandSand"))
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding()
                    } else if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Color("BrandSand"))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {

                                // Existing watchlists
                                if !watchlists.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Your Watchlists")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("BrandTeal"))
                                            .padding(.horizontal, 20)
                                            .padding(.top, 16)

                                        ForEach(watchlists) { wl in
                                            Button {
                                                Task { await addToExisting(wl) }
                                            } label: {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(wl.name)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(.white)
                                                        Text("\(wl.movie_count) movies")
                                                            .font(.caption)
                                                            .foregroundStyle(.white.opacity(0.5))
                                                    }
                                                    Spacer()
                                                    Image(systemName: "plus.circle")
                                                        .foregroundStyle(Color("BrandGold"))
                                                }
                                                .padding(16)
                                                .background(Color.white.opacity(0.06))
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                                .padding(.horizontal, 20)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                // Create new watchlist
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(watchlists.isEmpty ? "Create a Watchlist" : "New Watchlist")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("BrandTeal"))
                                        .padding(.horizontal, 20)
                                        .padding(.top, watchlists.isEmpty ? 16 : 8)

                                    if showNewWatchlistField {
                                        VStack(spacing: 12) {
                                            TextField("Watchlist name", text: $newWatchlistName)
                                                .foregroundStyle(.white)
                                                .padding()
                                                .background(Color.white.opacity(0.08))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .padding(.horizontal, 20)

                                            Button {
                                                Task { await createAndAdd() }
                                            } label: {
                                                Group {
                                                    if isCreating {
                                                        ProgressView().tint(.white)
                                                    } else {
                                                        Text("Create & Add")
                                                            .font(.headline.weight(.semibold))
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color("BrandGold"))
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                            }
                                            .disabled(newWatchlistName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                                            .padding(.horizontal, 20)
                                        }
                                    } else {
                                        Button {
                                            withAnimation { showNewWatchlistField = true }
                                        } label: {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundStyle(Color("BrandGold"))
                                                Text("Create New Watchlist")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.white)
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .padding(.horizontal, 20)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                if let error = errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(Color("BrandRust"))
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .foregroundStyle(Color("BrandTeal"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task { await loadWatchlists() }
    }

    private func loadWatchlists() async {
        isLoading = true
        do {
            watchlists = try await service.fetchWatchlists(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func addToExisting(_ wl: PersonalWatchlist) async {
        guard let movieId = movie.localId else { return }
        errorMessage = nil
        do {
            try await service.addMovie(token: token, watchlistId: wl.id, movieId: movieId)
            successMessage = "Added to \"\(wl.name)\""
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onDismiss()
        } catch {
            errorMessage = "Couldn't add to watchlist."
        }
    }

    private func createAndAdd() async {
        guard let movieId = movie.localId else { return }
        let name = newWatchlistName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isCreating = true
        errorMessage = nil
        do {
            let wl = try await service.createWatchlist(token: token, name: name)
            try await service.addMovie(token: token, watchlistId: wl.id, movieId: movieId)
            successMessage = "Added to \"\(wl.name)\""
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onDismiss()
        } catch {
            errorMessage = "Couldn't create watchlist."
        }
        isCreating = false
    }
}
