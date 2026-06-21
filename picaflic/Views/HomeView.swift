import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authStore: AuthStore

    private let homeService = HomeService()
    private let preferenceService = PreferenceService()

    // MARK: - Scroll mode state
    @State private var isSwipeMode = false
    @State private var movies: [FeedItem] = []
    @State private var likedIds: Set<Int> = []
    @State private var dislikedIds: Set<Int> = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var addToWatchlistMovie: FeedItem? = nil
    @State private var hasMore = true
    @State private var isLoadingMore = false
    @State private var currentOffset = 0
    @State private var pageSize = 20
    @State private var showAllServices = true
    @State private var selectedServiceId: Int? = nil
    @State private var selectedGenre: String? = nil
    @State private var selectedType: String? = nil
    @State private var showGenrePicker = false
    @State private var showTypePicker = false
    @State private var showServicePicker = false

    // MARK: - Swipe mode state
    @State private var swipeItems: [FeedItem] = []
    @State private var swipeIndex = 0
    @State private var swipeIsLoading = false
    @State private var swipeDragOffset: CGSize = .zero
    @State private var swipeIsShowingBack = false
    @State private var swipeFeedbackMessage = ""
    @State private var showSwipeFeedback = false
    @State private var swipeLoadedDetails: [Int: MovieDetails] = [:]
    @State private var swipeIsLoadingDetails = false

    private let genres = [
        "Action", "Adventure", "Animation", "Comedy", "Crime",
        "Documentary", "Drama", "Family", "Fantasy", "Horror",
        "Mystery", "Romance", "Sci-Fi", "Thriller", "War", "Western"
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.bottom, 12)

                if isSwipeMode {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            if showSwipeFeedback {
                                Text(swipeFeedbackMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("BrandTeal"))
                                    .clipShape(Capsule())
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .padding(.bottom, 8)
                            }

                            Spacer()

                            if swipeIsLoading {
                                ProgressView("Loading picks...")
                                    .tint(Color("BrandSand"))
                                    .foregroundStyle(Color("BrandSand"))
                            } else if let item = swipeCurrentItem {
                                swipeCard(for: item, availableHeight: geo.size.height)
                            } else {
                                swipeEmptyState
                            }

                            Spacer()

                            swipeControlsView
                                .padding(.bottom, 20)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                } else {
                    searchBar
                        .padding(.bottom, 8)
                    filterRow
                        .padding(.bottom, 8)

                    if isLoading {
                        Spacer()
                        ProgressView("Loading movies...")
                            .tint(Color("BrandSand"))
                            .foregroundStyle(Color("BrandSand"))
                        Spacer()
                    } else if !errorMessage.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .foregroundStyle(Color("BrandRust"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            Button("Try Again") {
                                Task { await loadHome(reset: true) }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color("BrandTeal"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        Spacer()
                    } else if filteredMovies.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(filteredMovies) { movie in
                                    movieCard(movie)
                                }
                            }
                            .padding(.horizontal, 20)

                            if isLoadingMore {
                                ProgressView()
                                    .tint(Color("BrandSand"))
                                    .padding(.vertical, 20)
                            }

                            if hasMore && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        Task { await loadHome(reset: false) }
                                    }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .task {
            if movies.isEmpty {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await loadHome(reset: true)
            }
        }
        .onChange(of: isSwipeMode) { entering in
            errorMessage = ""
            if entering && swipeItems.isEmpty {
                Task { await loadSwipeFeed() }
            }
        }
        .refreshable { await loadHome(reset: true) }
        .sheet(isPresented: $showGenrePicker) { genrePickerSheet }
        .sheet(isPresented: $showTypePicker) { typePickerSheet }
        .sheet(isPresented: $showServicePicker) { servicePickerSheet }
        .sheet(item: $addToWatchlistMovie) { movie in
            if let token = authStore.accessToken {
                AddToWatchlistSheet(movie: movie, token: token) {
                    addToWatchlistMovie = nil
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
                Text("Pic-a-Flic")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color("BrandSand"))

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSwipeMode = false
                        }
                    } label: {
                        Text("Scroll")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSwipeMode ? Color("BrandSand").opacity(0.6) : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSwipeMode ? Color.clear : Color("BrandTeal"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSwipeMode = true
                        }
                    } label: {
                        Text("Swipe")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSwipeMode ? .white : Color("BrandSand").opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSwipeMode ? Color("BrandTeal") : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    // MARK: - Swipe Card

    @ViewBuilder
    private func swipeCard(for item: FeedItem, availableHeight: CGFloat) -> some View {
        let cardHeight = min(availableHeight * 0.65, 420.0)
        let imageHeight = cardHeight * 0.72

        VStack(spacing: 0) {
            ZStack {
                if swipeIsShowingBack {
                    swipeBackCard(for: item, cardHeight: cardHeight)
                } else {
                    swipeFrontCard(for: item, cardHeight: cardHeight, imageHeight: imageHeight)
                }
            }
            .frame(width: 300, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
        .offset(x: swipeDragOffset.width, y: swipeDragOffset.height * 0.15)
        .rotationEffect(.degrees(Double(swipeDragOffset.width / 20)))
        .overlay(
            ZStack {
                Text("❤️ LIKE")
                    .font(.title.weight(.black))
                    .foregroundStyle(Color("BrandTeal"))
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .rotationEffect(.degrees(-15))
                    .opacity(swipeDragOffset.width > 40 ? Double(swipeDragOffset.width / 80) : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)

                Text("⏭ SKIP")
                    .font(.title.weight(.black))
                    .foregroundStyle(Color("BrandGold"))
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .rotationEffect(.degrees(15))
                    .opacity(swipeDragOffset.width < -40 ? Double(-swipeDragOffset.width / 80) : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(20)
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.easeInOut(duration: 0.35)) {
                    swipeIsShowingBack.toggle()
                }
                if swipeIsShowingBack {
                    Task { await swipeFetchDetails(for: item) }
                }
            }
        )
        .gesture(
            DragGesture()
                .onChanged { value in swipeDragOffset = value.translation }
                .onEnded { value in handleSwipeGesture(value) }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: swipeDragOffset)
    }

    private func swipeFrontCard(for item: FeedItem, cardHeight: CGFloat, imageHeight: CGFloat) -> some View {
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
            .frame(width: 300, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    swipeTagView(item.isTV ? "TV" : "Movie", color: Color("BrandTeal"))
                    if let year = formattedYear(from: item.release_date) {
                        swipeTagView(year, color: Color("BrandGold"))
                    }
                    if let asset = item.providerAsset {
                        Image(asset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text("Tap card for details")
                    .font(.caption)
                    .foregroundStyle(Color("BrandTeal"))
            }
            .frame(width: 300, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color("BrandCharcoal"))
        }
    }

    private func swipeBackCard(for item: FeedItem, cardHeight: CGFloat) -> some View {
        let details = item.localId.flatMap { swipeLoadedDetails[$0] }

        return RoundedRectangle(cornerRadius: 24)
            .fill(Color("BrandTeal"))
            .overlay {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            swipeTagView(item.isTV ? "TV Show" : "Movie", color: Color.white.opacity(0.25))
                            if let release = item.release_date, !release.isEmpty {
                                swipeTagView(String(release.prefix(4)), color: Color.white.opacity(0.25))
                            }
                            if let runtime = details?.runtime, runtime > 0 {
                                swipeTagView("\(runtime) min", color: Color.white.opacity(0.25))
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

                        Divider().overlay(.white.opacity(0.3))

                        if swipeIsLoadingDetails {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        } else if let overview = details?.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("Tap card to flip back")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .frame(width: 300, height: cardHeight)
    }

    // MARK: - Swipe Controls

    private var swipeControlsView: some View {
        HStack(spacing: 18) {
            swipeControlButton(systemName: "backward.end.fill", color: Color("BrandTeal")) {
                swipeHandleRewind()
            }
            swipeControlButton(systemName: "xmark", color: Color("BrandRust")) {
                Task { await swipeHandleDislike() }
            }
            Button {
                addToWatchlistMovie = swipeCurrentItem
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color("BrandTeal"))
                    .clipShape(Circle())
            }
            swipeControlButton(systemName: "forward.end.fill", color: Color("BrandTeal")) {
                Task { await swipeHandlePass() }
            }
        }
    }

    private func swipeControlButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(color)
                .clipShape(Circle())
        }
    }

    private func swipeTagView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }

    private var swipeEmptyState: some View {
        VStack(spacing: 16) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            Text("No more picks right now")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("BrandSand"))
            Button("Reload Deck") {
                Task { await loadSwipeFeed() }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("BrandGold"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var swipeCurrentItem: FeedItem? {
        guard swipeItems.indices.contains(swipeIndex) else { return nil }
        return swipeItems[swipeIndex]
    }

    // MARK: - Swipe Helpers

    private func swipeShowFeedback(_ message: String) {
        swipeFeedbackMessage = message
        withAnimation { showSwipeFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSwipeFeedback = false }
        }
    }

    private func swipeHandleRewind() {
        guard swipeIndex > 0 else { return }
        swipeIndex -= 1
        swipeDragOffset = .zero
        swipeIsShowingBack = false
        swipeShowFeedback("⏮ Going back")
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let amount = value.translation.width
        if amount > 120 {
            Task { await swipeHandleLike() }
        } else if amount < -120 {
            Task { await swipeHandlePass() }
        } else {
            swipeDragOffset = .zero
        }
    }

    private func swipeMoveForward() {
        if swipeIndex < swipeItems.count - 1 {
            swipeIndex += 1
            swipePreloadNext()
        } else {
            swipeIndex = swipeItems.count
        }
    }

    private func swipePreloadNext() {
        let next = swipeIndex + 1
        guard swipeItems.indices.contains(next),
              let url = swipeItems[next].posterURL else { return }
        URLSession.shared.dataTask(with: url).resume()
    }

    private func swipeFetchDetails(for item: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = item.localId,
              swipeLoadedDetails[localId] == nil else { return }
        swipeIsLoadingDetails = true
        do {
            let details = try await homeService.fetchDetails(
                token: token,
                tmdbId: item.tmdb_id,
                isTV: item.isTV
            )
            swipeLoadedDetails[localId] = details
        } catch {
            print("SWIPE DETAILS ERROR:", error)
        }
        swipeIsLoadingDetails = false
    }

    // MARK: - Swipe Actions

    private func swipeHandleLike() async {
        guard let token = authStore.accessToken,
              let item = swipeCurrentItem,
              let localId = item.localId else { return }
        do {
            _ = try await preferenceService.setPreference(token: token, movieId: localId, status: "liked")
            swipeShowFeedback("❤️ Added to Likes")
        } catch {
            print("SWIPE LIKE ERROR:", error)
        }
        swipeDragOffset = .zero
        swipeIsShowingBack = false
        swipeMoveForward()
    }

    private func swipeHandlePass() async {
        swipeDragOffset = .zero
        swipeIsShowingBack = false
        swipeShowFeedback("⏭ Skipped")
        swipeMoveForward()
    }

    private func swipeHandleDislike() async {
        guard let token = authStore.accessToken,
              let item = swipeCurrentItem,
              let localId = item.localId else { return }
        defer {
            swipeDragOffset = .zero
            swipeIsShowingBack = false
            swipeMoveForward()
        }
        do {
            _ = try await preferenceService.setPreference(token: token, movieId: localId, status: "disliked")
            swipeShowFeedback("✕ Removed from deck")
        } catch {
            print("SWIPE DISLIKE ERROR:", error)
        }
    }

    private func loadSwipeFeed() async {
        guard let token = authStore.accessToken else { return }
        swipeIsLoading = true
        swipeIndex = 0
        swipeIsShowingBack = false
        do {
            let response = try await homeService.fetchHomeFeed(token: token, limit: 30, offset: 0)
            swipeItems = response.results
            swipePreloadNext()
        } catch {
            print("SWIPE FEED ERROR:", error)
        }
        swipeIsLoading = false
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("BrandSand").opacity(0.8))
            TextField("Search movies or shows", text: $searchText)
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadHome(reset: true) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("BrandSand").opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {

                // Services picker
                Button {
                    showServicePicker = true
                } label: {
                    HStack(spacing: 4) {
                        if let sid = selectedServiceId,
                           let service = availableServices.first(where: { $0.0 == sid }) {
                            if let asset = service.2 {
                                Image(asset)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 14, height: 14)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            Text(service.1)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                        } else {
                            Text("All Services")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedServiceId != nil ? .white : Color("BrandSand"))
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(selectedServiceId != nil ? .white : Color("BrandSand"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedServiceId != nil ? Color("BrandTeal") : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Genre picker
                Button {
                    showGenrePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedGenre ?? "Genre")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedGenre != nil ? .white : Color("BrandSand"))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(selectedGenre != nil ? .white : Color("BrandSand"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedGenre != nil ? Color("BrandTeal") : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Movies / TV picker
                Button {
                    showTypePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedType == "movie" ? "Movies" : selectedType == "tv" ? "TV" : "Movies & TV")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedType != nil ? .white : Color("BrandSand"))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(selectedType != nil ? .white : Color("BrandSand"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedType != nil ? Color("BrandTeal") : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }


    // MARK: - Genre Sheet

    private var genrePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()
                List {
                    Button {
                        selectedGenre = nil
                        showGenrePicker = false
                    } label: {
                        HStack {
                            Text("All Genres").foregroundStyle(.white)
                            Spacer()
                            if selectedGenre == nil {
                                Image(systemName: "checkmark").foregroundStyle(Color("BrandTeal"))
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    ForEach(genres, id: \.self) { genre in
                        Button {
                            selectedGenre = genre
                            showGenrePicker = false
                        } label: {
                            HStack {
                                Text(genre).foregroundStyle(.white)
                                Spacer()
                                if selectedGenre == genre {
                                    Image(systemName: "checkmark").foregroundStyle(Color("BrandTeal"))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Genre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showGenrePicker = false }
                        .foregroundStyle(Color("BrandTeal"))
                }
            }
        }
        .presentationDetents([.medium])
    }

        private var servicePickerSheet: some View {
            NavigationStack {
                ZStack {
                    Color("BrandCharcoal").ignoresSafeArea()
                    List {
                        Button {
                            selectedServiceId = nil
                            showAllServices = true
                            showServicePicker = false
                        } label: {
                            HStack {
                                Text("All Services").foregroundStyle(.white)
                                Spacer()
                                if selectedServiceId == nil {
                                    Image(systemName: "checkmark").foregroundStyle(Color("BrandTeal"))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))

                        ForEach(availableServices, id: \.0) { (providerId, name, asset) in
                            Button {
                                selectedServiceId = providerId
                                showAllServices = false
                                showServicePicker = false
                            } label: {
                                HStack {
                                    if let asset {
                                        Image(asset)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 22, height: 22)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                    Text(name).foregroundStyle(.white)
                                    Spacer()
                                    if selectedServiceId == providerId {
                                        Image(systemName: "checkmark").foregroundStyle(Color("BrandTeal"))
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Streaming Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showServicePicker = false }
                            .foregroundStyle(Color("BrandTeal"))
                    }
                }
            }
            .presentationDetents([.medium])
        }
    // MARK: - Type Sheet

    private var typePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()
                List {
                    ForEach([
                        (nil as String?, "Movies & TV"),
                        ("movie", "Movies only"),
                        ("tv", "TV only")
                    ], id: \.1) { (value, label) in
                        Button {
                            selectedType = value
                            showTypePicker = false
                        } label: {
                            HStack {
                                Text(label).foregroundStyle(.white)
                                Spacer()
                                if selectedType == value {
                                    Image(systemName: "checkmark").foregroundStyle(Color("BrandTeal"))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showTypePicker = false }
                        .foregroundStyle(Color("BrandTeal"))
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    // MARK: - Computed

    private var availableServices: [(Int, String, String?)] {
        var seen = Set<Int>()
        var result: [(Int, String, String?)] = []
        for movie in movies {
            guard let pid = movie.provider_id,
                  let name = movie.provider_name,
                  !seen.contains(pid) else { continue }
            seen.insert(pid)
            result.append((pid, name, movie.providerAsset))
        }
        return result.sorted { $0.1 < $1.1 }
    }

    private var filteredMovies: [FeedItem] {
        movies.filter { movie in
            if let id = movie.localId, dislikedIds.contains(id) { return false }
            if let sid = selectedServiceId, movie.provider_id != sid { return false }
            if let type = selectedType {
                if type == "movie" && movie.isTV { return false }
                if type == "tv" && !movie.isTV { return false }
            }
            if let genre = selectedGenre, !movie.genreNames.contains(genre) { return false }
            return true
        }
    }

    // MARK: - Movie Card

    private func movieCard(_ movie: FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let posterURL = movie.posterURL {
                        AsyncImage(url: posterURL) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08))
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
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                if let asset = movie.providerAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    tagView(movie.isTV ? "TV" : "Movie")
                    if let year = formattedYear(from: movie.release_date) {
                        tagView(year)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await likeMovie(movie) }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(likeColor(for: movie))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        addToWatchlistMovie = movie
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color("BrandTeal"))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await dislikeMovie(movie) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(dislikeColor(for: movie))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Helpers

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            Text("No movies found")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
            Text("Try another search or refresh your feed.")
                .foregroundStyle(Color("BrandSand").opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color("BrandGold"))
            .clipShape(Capsule())
    }

    private func formattedYear(from releaseDate: String?) -> String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    private func likeColor(for movie: FeedItem) -> Color {
        guard let id = movie.localId else { return Color("BrandGold") }
        return likedIds.contains(id) ? Color("BrandTeal") : Color("BrandGold")
    }

    private func dislikeColor(for movie: FeedItem) -> Color {
        guard let id = movie.localId else { return Color("BrandRust") }
        return dislikedIds.contains(id) ? Color("BrandTeal") : Color("BrandRust")
    }

    // MARK: - Data

    private func loadHome(reset: Bool = true) async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSearch.isEmpty else { return }

        if reset {
            isLoading = true
            errorMessage = ""
            currentOffset = 0
            hasMore = true
        } else {
            guard !isLoading, !isLoadingMore, hasMore else { return }
            isLoadingMore = true
        }

        do {
            let response = try await homeService.fetchHomeFeed(
                token: token,
                limit: pageSize,
                offset: currentOffset
            )
            if reset {
                movies = response.results
            } else {
                let existingIds = Set(movies.compactMap(\.id))
                let newItems = response.results.filter { item in
                    guard let id = item.id else { return true }
                    return !existingIds.contains(id)
                }
                movies.append(contentsOf: newItems)
            }
            currentOffset += response.results.count
            hasMore = response.meta.has_more && !response.results.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            print("HOME LOAD ERROR:", error)
        }

        if reset { isLoading = false } else { isLoadingMore = false }
    }

    private func runSearch() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await loadHome(reset: true)
            return
        }
        isLoading = true
        errorMessage = ""
        hasMore = false
        do {
            movies = try await homeService.searchMovies(token: token, query: trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func likeMovie(_ movie: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = movie.localId else { return }
        do {
            _ = try await preferenceService.setPreference(token: token, movieId: localId, status: "liked")
            likedIds.insert(localId)
            dislikedIds.remove(localId)
        } catch {
            print("LIKE MOVIE ERROR:", error)
        }
    }

    private func dislikeMovie(_ movie: FeedItem) async {
        guard let token = authStore.accessToken,
              let localId = movie.localId else { return }
        do {
            _ = try await preferenceService.setPreference(token: token, movieId: localId, status: "disliked")
            dislikedIds.insert(localId)
            likedIds.remove(localId)
        } catch {
            print("DISLIKE MOVIE ERROR:", error)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthStore())
    }
}
