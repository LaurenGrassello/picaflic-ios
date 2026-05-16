import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authStore: AuthStore

    private let homeService = HomeService()
    private let preferenceService = PreferenceService()

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

    // Filters
    @State private var showAllServices = true
    @State private var selectedServiceId: Int? = nil
    @State private var selectedGenre: String? = nil
    @State private var selectedType: String? = nil  // nil = all, "movie", "tv"
    @State private var showGenrePicker = false
    @State private var showTypePicker = false

    private let genres = [
        "Action", "Adventure", "Animation", "Comedy", "Crime",
        "Documentary", "Drama", "Family", "Fantasy", "Horror",
        "Mystery", "Romance", "Sci-Fi", "Thriller", "War", "Western"
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 16) {
                    headerView
                    searchBar
                    filterRow

                    if isLoading {
                        Spacer()
                        ProgressView("Loading movies...")
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
            .task {
                if movies.isEmpty {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    await loadHome(reset: true)
                }
            }
            .refreshable {
                await loadHome(reset: true)
            }
            .sheet(isPresented: $showGenrePicker) {
                genrePickerSheet
            }
            .sheet(isPresented: $showTypePicker) {
                typePickerSheet
            }
            .sheet(item: $addToWatchlistMovie) { movie in
                if let token = authStore.accessToken {
                    AddToWatchlistSheet(movie: movie, token: token) {
                        addToWatchlistMovie = nil
                    }
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
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("BrandSand").opacity(0.8))

            TextField("Search movies or shows", text: $searchText)
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit {
                    Task { await runSearch() }
                }

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

                // All Services toggle
                Button {
                    showAllServices = true
                    selectedServiceId = nil
                } label: {
                    Text("All Services")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(showAllServices ? .white : Color("BrandSand"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(showAllServices ? Color("BrandTeal") : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Individual service pills from loaded movies
                ForEach(availableServices, id: \.0) { (providerId, name, asset) in
                    Button {
                        if selectedServiceId == providerId {
                            selectedServiceId = nil
                            showAllServices = true
                        } else {
                            selectedServiceId = providerId
                            showAllServices = false
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if let asset {
                                Image(asset)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 18, height: 18)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Text(name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedServiceId == providerId ? .white : Color("BrandSand"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedServiceId == providerId ? Color("BrandTeal") : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

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
                            Text("All Genres")
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedGenre == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color("BrandTeal"))
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
                                Text(genre)
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedGenre == genre {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("BrandTeal"))
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
                                Text(label)
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedType == value {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("BrandTeal"))
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

    // Unique services present in the current feed
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
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.08))
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

                // Service icon badge top-left
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
            print("HOME SEARCH ERROR:", error)
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
    HomeView()
        .environmentObject(AuthStore())
}
