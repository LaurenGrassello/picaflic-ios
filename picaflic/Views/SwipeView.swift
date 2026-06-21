import SwiftUI

struct SwipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    let watchlistId: Int
    let watchlistName: String

    private let watchlistService = WatchlistService()
    private let preferenceService = PreferenceService()

    @State private var items: [FeedItem] = []
    @State private var currentIndex = 0
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingBack = false
    @State private var showMatchAlert = false
    @State private var lastMatchNames: String = ""
    @State private var showMatchesScreen = false
    @State private var likedCurrentItem = false
    @State private var likeFeedbackMessage = ""
    @State private var showLikeFeedback = false
    @State private var loadedDetails: [Int: MovieDetails] = [:]
    @State private var isLoadingDetails = false

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView

                Spacer()

                if showLikeFeedback {
                    Text(likeFeedbackMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("BrandTeal"))
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if isLoading {
                    ProgressView("Loading picks...")
                        .tint(Color("BrandSand"))
                        .foregroundStyle(Color("BrandSand"))
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(Color("BrandRust"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else if let item = currentItem {
                    swipeCard(for: item)
                } else {
                    emptyStateView
                }

                Spacer()

                controlsView
                    .padding(.bottom, 90)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showMatchesScreen) {
            WatchlistMatchesView(
                watchlistId: watchlistId,
                watchlistName: watchlistName
            )
        }
        .task {
            if items.isEmpty {
                await loadDeck()
            }
        }
        .alert("It's a Match!", isPresented: $showMatchAlert) {
            Button("View Matches") { }
            Button("Keep Swiping", role: .cancel) { }
        } message: {
            Text(lastMatchNames.isEmpty ? "Your group matched on this movie." : lastMatchNames)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Pic-a-Flic")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color("BrandSand"))
                }
                .buttonStyle(.plain)
                Spacer()
            }

            HStack {
                Spacer()
                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                Spacer()
            }

            HStack {
                Text(watchlistName)
                    .font(.headline)
                    .foregroundStyle(Color("BrandTeal"))
                Spacer()
            }
        }
    }

    // MARK: - Swipe Card

    @ViewBuilder
    private func swipeCard(for item: FeedItem) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if isShowingBack {
                    backCardView(for: item)
                } else {
                    frontCardView(for: item)
                }
            }
            .frame(width: 300, height: 520)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
        .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isShowingBack.toggle()
                }
                // Fetch when flipping TO the back (isShowingBack just became true)
                if isShowingBack, let item = currentItem {
                    Task { await fetchDetails(for: item) }
                }
            }
        )
        .gesture(
            DragGesture()
                .onChanged { value in dragOffset = value.translation }
                .onEnded { value in handleSwipeGesture(value) }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
    }

    // MARK: - Front Card

    private func frontCardView(for item: FeedItem) -> some View {
        VStack(spacing: 0) {
            Group {
                if let posterURL = item.posterURL {
                    AsyncImage(url: posterURL, transaction: Transaction(animation: .easeIn)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.08))
                                ProgressView().tint(Color("BrandSand"))
                            }
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            VHSMoviePlaceholderView()
                        @unknown default:
                            VHSMoviePlaceholderView()
                        }
                    }
                } else {
                    VHSMoviePlaceholderView()
                }
            }
            .frame(width: 300, height: 410)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    tagView(item.isTV ? "TV" : "Movie", color: Color("BrandTeal"))
                    if let year = formattedYear(from: item.release_date) {
                        tagView(year, color: Color("BrandGold"))
                    }
                }

                Text("Tap card for details")
                    .font(.caption)
                    .foregroundStyle(Color("BrandTeal"))
                    .padding(.top, 2)
            }
            .frame(width: 300, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 14)
        }
        .background(Color.clear)
    }

    // MARK: - Back Card

    private func backCardView(for item: FeedItem) -> some View {
        let details = item.localId.flatMap { loadedDetails[$0] }

        return RoundedRectangle(cornerRadius: 24)
            .fill(Color("BrandTeal"))
            .overlay {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Title
                        Text(item.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)

                        // Type + year + runtime
                        HStack(spacing: 8) {
                            Text(item.isTV ? "TV Show" : "Movie")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())

                            if let release = item.release_date, !release.isEmpty {
                                Text(String(release.prefix(4)))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }

                            if let runtime = details?.runtime, runtime > 0 {
                                Text("\(runtime) min")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }

                        // Genres
                        if !item.genreNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(item.genreNames, id: \.self) { genre in
                                        Text(genre)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("BrandTeal"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white.opacity(0.9))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Divider().overlay(.white.opacity(0.25))

                        // Overview
                        if isLoadingDetails {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Loading details...")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        } else if let overview = details?.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider().overlay(.white.opacity(0.25))

                        // Watchlist Pick section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Watchlist Pick")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Fast-forward adds a pick for this group. If 2+ members pick it, it becomes a match.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Actions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Actions")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Heart = personal like • X = never show again • Rewind = pass for now")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Spacer(minLength: 8)

                        Text("Tap card to flip back")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(24)
                }
            }
            .frame(width: 300, height: 520)
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 18) {
            controlButton(systemName: "backward.end.fill", color: Color("BrandTeal")) {
                Task { await handlePass() }
            }
            controlButton(systemName: "xmark", color: Color("BrandRust")) {
                Task { await handleDislike() }
            }
            controlButton(
                systemName: "heart.fill",
                color: likedCurrentItem ? Color("BrandTeal") : Color("BrandGold")
            ) {
                Task { await handleLike() }
            }
            controlButton(systemName: "forward.end.fill", color: Color("BrandTeal")) {
                Task { await handlePick() }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
            Text("No more picks right now")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("BrandSand"))
            Button("Reload Deck") {
                Task { await loadDeck() }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("BrandGold"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helpers

    private func tagView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }

    private func controlButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(color)
                .clipShape(Circle())
        }
    }

    private var currentItem: FeedItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    private func formattedYear(from releaseDate: String?) -> String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    private func preloadNextImage() {
        let nextIndex = currentIndex + 1
        guard items.indices.contains(nextIndex),
              let url = items[nextIndex].posterURL else { return }
        URLSession.shared.dataTask(with: url).resume()
    }

    // MARK: - Details

    private func fetchDetails(for item: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = item.localId,
              loadedDetails[localId] == nil else { return }

        isLoadingDetails = true
        do {
            let details = try await HomeService().fetchDetails(
                token: token,
                tmdbId: item.tmdb_id,
                isTV: item.isTV
            )
            loadedDetails[localId] = details
        } catch {
            print("DETAILS ERROR:", error)
        }
        isLoadingDetails = false
    }

    // MARK: - Data

    private func loadDeck() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        errorMessage = ""
        isLoading = true
        currentIndex = 0
        isShowingBack = false
        likedCurrentItem = false

        do {
            items = try await watchlistService.fetchWatchlistDeck(
                token: token,
                watchlistId: watchlistId
            )
            preloadNextImage()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Gesture

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        if horizontalAmount > 120 {
            Task { await handlePick() }
        } else if horizontalAmount < -120 {
            Task { await handlePass() }
        } else {
            dragOffset = .zero
        }
    }

    // MARK: - Actions

    private func handlePick() async {
        guard let token = authStore.accessToken,
              let item = currentItem,
              let localId = item.localId else { return }

        defer {
            dragOffset = .zero
            isShowingBack = false
            moveForward()
        }

        do {
            let response = try await watchlistService.sendWatchlistSwipe(
                token: token,
                watchlistId: watchlistId,
                movieId: localId,
                status: "picked"
            )

            if response.match {
                let otherNames = response.matched_users
                    .map(\.display_name)
                    .joined(separator: ", ")
                lastMatchNames = otherNames.isEmpty
                    ? "Your group matched on this movie."
                    : "\(otherNames) also picked this movie."
                showMatchAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handlePass() async {
        guard let token = authStore.accessToken,
              let item = currentItem,
              let localId = item.localId else { return }

        defer {
            dragOffset = .zero
            isShowingBack = false
            moveForward()
        }

        do {
            _ = try await watchlistService.sendWatchlistSwipe(
                token: token,
                watchlistId: watchlistId,
                movieId: localId,
                status: "passed"
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleLike() async {
        guard let token = authStore.accessToken,
              let item = currentItem,
              let localId = item.localId else { return }

        dragOffset = .zero
        isShowingBack = false

        do {
            _ = try await preferenceService.setPreference(
                token: token,
                movieId: localId,
                status: "liked"
            )
            likedCurrentItem = true
            likeFeedbackMessage = "Added to Likes"
            withAnimation { showLikeFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showLikeFeedback = false }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleDislike() async {
        guard let token = authStore.accessToken,
              let item = currentItem,
              let localId = item.localId else { return }

        defer {
            dragOffset = .zero
            isShowingBack = false
            moveForward()
        }

        do {
            _ = try await preferenceService.setPreference(
                token: token,
                movieId: localId,
                status: "disliked"
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveForward() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            likedCurrentItem = false
            preloadNextImage()
        } else {
            currentIndex = items.count
            likedCurrentItem = false
        }
    }
}

#Preview {
    NavigationStack {
        SwipeView(watchlistId: 1, watchlistName: "Friday Night Picks")
            .environmentObject(AuthStore())
    }
}
