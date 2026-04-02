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
}
