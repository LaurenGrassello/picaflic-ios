import Foundation

final class PersonalWatchlistService {
    private let api = APIClient.shared

    func fetchWatchlists(token: String) async throws -> [PersonalWatchlist] {
        let response: PersonalWatchlistsResponse = try await api.request(
            path: "/personal-watchlists",
            token: token
        )
        return response.results
    }

    func createWatchlist(token: String, name: String) async throws -> PersonalWatchlist {
        struct Body: Encodable { let name: String }
        struct CreateResponse: Decodable { let watchlist: PersonalWatchlist }
        let response: CreateResponse = try await api.request(
            path: "/personal-watchlists",
            method: "POST",
            token: token,
            body: Body(name: name)
        )
        return response.watchlist
    }

    func addMovie(token: String, watchlistId: Int, movieId: Int) async throws {
        struct Body: Encodable { let movie_id: Int }
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)/movies",
            method: "POST",
            token: token,
            body: Body(movie_id: movieId)
        )
    }

    func removeMovie(token: String, watchlistId: Int, movieId: Int) async throws {
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)/movies/\(movieId)",
            method: "DELETE",
            token: token
        )
    }

    func deleteWatchlist(token: String, watchlistId: Int) async throws {
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)",
            method: "DELETE",
            token: token
        )
    }
}
