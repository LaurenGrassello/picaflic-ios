import Foundation

final class WatchlistService {
    private let api = APIClient.shared

    func fetchWatchlists(token: String) async throws -> [WatchlistSummary] {
        let response: WatchlistsResponse = try await api.request(
            path: "/social/watchlists",
            token: token
        )
        return response.results
    }

    func fetchWatchlistMovies(token: String, watchlistId: Int) async throws -> [WatchlistMovie] {
        let response: WatchlistMoviesResponse = try await api.request(
            path: "/social/watchlists/\(watchlistId)/movies",
            token: token
        )
        return response.results
    }

    func fetchWatchlistDeck(token: String, watchlistId: Int) async throws -> [FeedItem] {
        let response: FeedResultsResponse = try await api.request(
            path: "/social/watchlists/\(watchlistId)/deck",
            token: token
        )
        return response.results
    }

    func sendWatchlistSwipe(
        token: String,
        watchlistId: Int,
        movieId: Int,
        status: String
    ) async throws -> WatchlistSwipeResponse {
        let body = WatchlistSwipeRequest(movie_id: movieId, status: status)

        let response: WatchlistSwipeResponse = try await api.request(
            path: "/social/watchlists/\(watchlistId)/swipe",
            method: "POST",
            token: token,
            body: body
        )
        return response
    }

    func createWatchlist(
        token: String,
        name: String,
        memberIds: [Int]
    ) async throws -> CreateWatchlistResponse {
        let body = CreateWatchlistRequest(name: name, member_ids: memberIds)

        return try await api.request(
            path: "/social/watchlists",
            method: "POST",
            token: token,
            body: body
        )
    }
}
