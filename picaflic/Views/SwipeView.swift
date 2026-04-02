import SwiftUI

struct SwipeView: View {
    @EnvironmentObject var authStore: AuthStore

    private let feedService = FeedService()
    private let swipeService = SwipeService()
    private let detailsService = TitleDetailsService()

    @State private var currentDetails: TitleDetails?
    @State private var isLoadingDetails = false
    @State private var items: [FeedItem] = []
    @State private var currentIndex = 0
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingBack = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    headerView

                    Spacer()

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
                }
                .padding()
            }
            .navigationBarHidden(true)
            .task {
                if items.isEmpty {
                    await loadFeed()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Spacer()
            }

            HStack {
                Button {
                    Task {
                        isShowingBack = false
                        dragOffset = .zero
                        await loadFeed()
                    }
                } label: {
                    Text("Pic-A-Flic")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("BrandSand"))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Logout") {
                    authStore.clear()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("BrandTeal"))
            }
        }
    }

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
            TapGesture()
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isShowingBack.toggle()
                    }
                }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleSwipeGesture(value)
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
    }
    
    private func loadDetailsForCurrentItem() async {
        guard let token = authStore.accessToken,
              let item = currentItem else {
            currentDetails = nil
            return
        }

        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            let kind = item.isTV ? "tv" : "movie"
            let details = try await detailsService.fetchDetails(
                token: token,
                kind: kind,
                tmdbId: item.tmdb_id
            )
            currentDetails = details
        } catch {
            print("DETAILS LOAD ERROR:", error)
            currentDetails = nil
        }
    }

    private func frontCardView(for item: FeedItem) -> some View {
        VStack(spacing: 0) {
            Group {
                if let posterURL = item.posterURL {
                    AsyncImage(url: posterURL, transaction: Transaction(animation: .easeIn)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.08))

                                ProgressView()
                                    .tint(Color("BrandSand"))
                            }

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Available on")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("BrandSand").opacity(0.75))

                    if isLoadingDetails {
                        ProgressView()
                            .tint(Color("BrandSand"))
                    } else if let providers = currentDetails?.providers, !providers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(providers) { provider in
                                    providerChip(provider)
                                }
                            }
                        }
                    } else {
                        Text("No providers available")
                            .font(.subheadline)
                            .foregroundStyle(Color("BrandSand").opacity(0.9))
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

    private func backCardView(for item: FeedItem) -> some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color("BrandTeal"))
            .overlay {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(3)

                    HStack(spacing: 10) {
                        Text(item.isTV ? "TV Show" : "Movie")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        if let release = item.release_date, !release.isEmpty {
                            Text(release)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    Divider()
                        .overlay(.white.opacity(0.25))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if isLoadingDetails {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentDetails?.overview?.isEmpty == false
                                 ? currentDetails?.overview ?? ""
                                 : "No summary available.")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where to watch")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if let providers = currentDetails?.providers, !providers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(providers) { provider in
                                        providerChip(provider)
                                    }
                                }
                            }
                        } else {
                            Text("No providers available.")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.95))
                        }
                    }

                    Spacer()

                    Text("Tap card to flip back")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(24)
            }
            .frame(width: 300, height: 520)
    }
    
    private func providerChip(_ provider: ProviderInfo) -> some View {
        HStack(spacing: 6) {
            if let logoURL = provider.logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .empty:
                        Color.white.opacity(0.15)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Color.white.opacity(0.15)
                    @unknown default:
                        Color.white.opacity(0.15)
                    }
                }
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(provider.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color("BrandTeal"))
        .clipShape(Capsule())
    }

    private var controlsView: some View {
        HStack(spacing: 18) {
            controlButton(
                systemName: "backward.end.fill",
                color: Color("BrandTeal")
            ) {
                moveBackward()
            }

            controlButton(
                systemName: "xmark",
                color: Color("BrandRust")
            ) {
                Task {
                    await submitCurrentSwipe(liked: false)
                }
            }

            controlButton(
                systemName: "heart.fill",
                color: Color("BrandGold")
            ) {
                Task {
                    await submitCurrentSwipe(liked: true)
                }
            }

            controlButton(
                systemName: "forward.end.fill",
                color: Color("BrandTeal")
            ) {
                moveForwardWithoutVote()
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

            Button("Reload Feed") {
                Task {
                    await loadFeed()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("BrandGold"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var fallbackView: some View {
        VHSMoviePlaceholderView()
    }

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
        guard items.indices.contains(nextIndex) else { return }
        guard let url = items[nextIndex].posterURL else { return }

        URLSession.shared.dataTask(with: url).resume()
    }

    private func loadFeed() async {
        errorMessage = ""
        isLoading = true
        currentIndex = 0
        isShowingBack = false

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }

        do {
            let results = try await feedService.fetchForYou(
                token: token,
                query: nil
            )
            items = results
            preloadNextImage()
            await loadDetailsForCurrentItem()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width

        if horizontalAmount > 120 {
            Task {
                await submitCurrentSwipe(liked: true)
            }
        } else if horizontalAmount < -120 {
            Task {
                await submitCurrentSwipe(liked: false)
            }
        } else {
            dragOffset = .zero
        }
    }

    private func submitCurrentSwipe(liked: Bool) async {
        guard let item = currentItem else { return }

        defer {
            dragOffset = .zero
            isShowingBack = false
            moveForward()
        }

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        guard let localId = item.localId else {
            return
        }

        do {
            try await swipeService.sendSwipe(
                token: token,
                movieId: localId,
                liked: liked
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveForward() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            preloadNextImage()
            Task {
                await loadDetailsForCurrentItem()
            }
        } else {
            currentIndex = items.count
        }
    }

    private func moveForwardWithoutVote() {
        dragOffset = .zero
        isShowingBack = false
        moveForward()
    }

    private func moveBackward() {
        guard !items.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        }
        dragOffset = .zero
        isShowingBack = false
        
        Task {
                await loadDetailsForCurrentItem()
            }
    }
}

#Preview {
    SwipeView()
        .environmentObject(AuthStore())
}
