import SwiftUI

struct PersonalShareSwipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    let shareId: Int
    let watchlistName: String
    let ownerName: String

    private let service = PersonalWatchlistService()

    @State private var items: [FeedItem] = []
    @State private var currentIndex = 0
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var dragOffset: CGSize = .zero
    @State private var showMatchAlert = false
    @State private var showMatchesScreen = false
    @State private var isShowingBack = false
    @State private var loadedDetails: [Int: MovieDetails] = [:]
    @State private var isLoadingDetails = false

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            GeometryReader { geo in
                let cardWidth = min(geo.size.width * 0.8, 320)
                let infoHeight: CGFloat = 130
                let reservedHeight: CGFloat = 170 + 58 + 24 + 24
                let maxCardHeight = max(geo.size.height - reservedHeight, 260)
                let cardHeight = min(cardWidth * 1.5 + infoHeight + 10, maxCardHeight)
                let imageHeight = cardHeight - infoHeight

                VStack(spacing: 16) {
                    headerView

                    Spacer(minLength: 0)

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
                        swipeCard(for: item, cardWidth: cardWidth, cardHeight: cardHeight, imageHeight: imageHeight)
                    } else {
                        emptyStateView
                    }

                    controlsView
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                }
                .padding()
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showMatchesScreen) {
            PersonalShareMatchesView(shareId: shareId, watchlistName: watchlistName)
        }
        .task {
            if items.isEmpty {
                await loadDeck()
            }
        }
        .alert("It's a Match!", isPresented: $showMatchAlert) {
            Button("View Matches") { showMatchesScreen = true }
            Button("Keep Swiping", role: .cancel) { }
        } message: {
            Text("You and \(ownerName) both want to watch this.")
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
                Text("from \(ownerName)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func swipeCard(for item: FeedItem, cardWidth: CGFloat, cardHeight: CGFloat, imageHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if isShowingBack {
                    backCardView(for: item, cardWidth: cardWidth, cardHeight: cardHeight)
                } else {
                    frontCardView(for: item, cardWidth: cardWidth, imageHeight: imageHeight)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
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

    private func frontCardView(for item: FeedItem, cardWidth: CGFloat, imageHeight: CGFloat) -> some View {
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
            .frame(width: cardWidth, height: imageHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.title3.weight(.bold))
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
            }
            .frame(width: cardWidth, alignment: .leading)
            .padding(.top, 12)
            .padding(.horizontal, 4)
        }
        .background(Color.clear)
    }

    // MARK: - Back Card

    private func backCardView(for item: FeedItem, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        let details = item.localId.flatMap { loadedDetails[$0] }

        return RoundedRectangle(cornerRadius: 24)
            .fill(Color("BrandTeal"))
            .overlay {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)

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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Move")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Heart = you want to watch this too • X = pass. If \(ownerName) already picked it, a heart is an instant match.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Text("Tap card to flip back")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(24)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 32) {
            controlButton(systemName: "xmark", color: Color("BrandRust")) {
                Task { await handleSwipe(status: "passed") }
            }
            controlButton(systemName: "heart.fill", color: Color("BrandGold")) {
                Task { await handleSwipe(status: "picked") }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
            Text("No more picks right now")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("BrandSand"))
            Button("View Matches") {
                showMatchesScreen = true
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
            print("SHARE SWIPE DETAILS ERROR:", error)
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

        do {
            items = try await service.fetchShareDeck(token: token, shareId: shareId)
            preloadNextImage()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        if horizontalAmount > 120 {
            Task { await handleSwipe(status: "picked") }
        } else if horizontalAmount < -120 {
            Task { await handleSwipe(status: "passed") }
        } else {
            dragOffset = .zero
        }
    }

    private func handleSwipe(status: String) async {
        guard let token = authStore.accessToken,
              let item = currentItem,
              let localId = item.localId else { return }

        defer {
            dragOffset = .zero
            isShowingBack = false
            moveForward()
        }

        do {
            let response = try await service.sendShareSwipe(
                token: token,
                shareId: shareId,
                movieId: localId,
                status: status
            )
            if response.match {
                showMatchAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveForward() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            preloadNextImage()
        } else {
            currentIndex = items.count
        }
    }
}

#Preview {
    NavigationStack {
        PersonalShareSwipeView(shareId: 1, watchlistName: "Date Night", ownerName: "Jess")
            .environmentObject(AuthStore())
    }
}
