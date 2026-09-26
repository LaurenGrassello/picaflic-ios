import Foundation

struct PersonalWatchlistShare: Codable, Identifiable {
    let share_id: Int
    let watchlist_id: Int
    let watchlist_name: String
    let owner_user_id: Int
    let owner_display_name: String
    let status: String
    let match_count: Int

    var id: Int { share_id }
}

struct PersonalWatchlistShareInfo: Codable {
    let share_id: Int
    let watchlist_id: Int
    let watchlist_name: String
    let owner_user_id: Int
    let owner_display_name: String
    let shared_with_user_id: Int
    let status: String
}

struct ShareSwipeResponse: Decodable {
    let ok: Bool
    let match: Bool
    let status: String
}

/// One recipient this watchlist has been shared with, from the owner's side.
struct PersonalWatchlistSentShare: Decodable, Identifiable {
    let share_id: Int
    let shared_with_user_id: Int
    let shared_with_display_name: String
    let status: String
    let match_count: Int

    var id: Int { share_id }
}

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

    func renameWatchlist(token: String, watchlistId: Int, name: String) async throws {
        struct Body: Encodable { let name: String }
        struct RenameResponse: Decodable { let ok: Bool }
        let _: RenameResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)",
            method: "PATCH",
            token: token,
            body: Body(name: name)
        )
    }

    /// Adds a movie to a personal watchlist.
    ///
    /// If `movie.localId` is already known (it came from somewhere already synced
    /// into our `movies` table, like the home feed), we send `movie_id` directly —
    /// same as before. If it's `nil` (e.g. a raw search result that has never been
    /// saved locally), we send the TMDB fields instead, and the backend will find
    /// or create the local `movies` row for us before adding it to the watchlist.
    func addMovie(token: String, watchlistId: Int, movie: FeedItem) async throws {
        struct Body: Encodable {
            let movie_id: Int?
            let tmdb_id: Int?
            let title: String?
            let poster_path: String?
            let genre_ids: String?
            let release_date: String?
            let popularity: Double?
        }
        struct OkResponse: Decodable { let ok: Bool }

        let body: Body
        if let localId = movie.localId {
            body = Body(
                movie_id: localId,
                tmdb_id: nil,
                title: nil,
                poster_path: nil,
                genre_ids: nil,
                release_date: nil,
                popularity: nil
            )
        } else {
            body = Body(
                movie_id: nil,
                tmdb_id: movie.tmdb_id,
                title: movie.title,
                poster_path: movie.poster_path,
                genre_ids: movie.genre_ids,
                release_date: movie.release_date,
                popularity: movie.popularity
            )
        }

        let _: OkResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)/movies",
            method: "POST",
            token: token,
            body: body
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

    // MARK: - Sharing

    func shareWatchlist(token: String, watchlistId: Int, friendUserId: Int) async throws -> Int {
        struct Body: Encodable { let friend_user_id: Int }
        struct ShareCreateResponse: Decodable { let ok: Bool; let share_id: Int; let status: String }
        let response: ShareCreateResponse = try await api.request(
            path: "/personal-watchlists/\(watchlistId)/share",
            method: "POST",
            token: token,
            body: Body(friend_user_id: friendUserId)
        )
        return response.share_id
    }

    /// Owner-only: everyone this watchlist has been shared with, plus their status
    /// and match count — powers the "Shared With" section on the owner's own
    /// watchlist detail screen.
    func fetchSentShares(token: String, watchlistId: Int) async throws -> [PersonalWatchlistSentShare] {
        struct Response: Decodable { let results: [PersonalWatchlistSentShare] }
        let response: Response = try await api.request(
            path: "/personal-watchlists/\(watchlistId)/shares",
            token: token
        )
        return response.results
    }

    func fetchReceivedShares(token: String) async throws -> [PersonalWatchlistShare] {
        struct ReceivedSharesResponse: Decodable { let results: [PersonalWatchlistShare] }
        let response: ReceivedSharesResponse = try await api.request(
            path: "/personal-watchlists/shares/received",
            token: token
        )
        return response.results
    }

    func fetchShareInfo(token: String, shareId: Int) async throws -> PersonalWatchlistShareInfo {
        try await api.request(
            path: "/personal-watchlists/shares/\(shareId)",
            token: token
        )
    }

    func acceptShare(token: String, shareId: Int) async throws {
        struct StatusResponse: Decodable { let ok: Bool; let status: String }
        let _: StatusResponse = try await api.request(
            path: "/personal-watchlists/shares/\(shareId)/accept",
            method: "POST",
            token: token
        )
    }

    func declineShare(token: String, shareId: Int) async throws {
        struct StatusResponse: Decodable { let ok: Bool; let status: String }
        let _: StatusResponse = try await api.request(
            path: "/personal-watchlists/shares/\(shareId)/decline",
            method: "POST",
            token: token
        )
    }

    func fetchShareDeck(token: String, shareId: Int) async throws -> [FeedItem] {
        let response: FeedResultsResponse = try await api.request(
            path: "/personal-watchlists/shares/\(shareId)/deck",
            token: token
        )
        return response.results
    }

    func sendShareSwipe(token: String, shareId: Int, movieId: Int, status: String) async throws -> ShareSwipeResponse {
        struct Body: Encodable { let movie_id: Int; let status: String }
        return try await api.request(
            path: "/personal-watchlists/shares/\(shareId)/swipe",
            method: "POST",
            token: token,
            body: Body(movie_id: movieId, status: status)
        )
    }

    func fetchShareMatches(token: String, shareId: Int) async throws -> [FeedItem] {
        let response: FeedResultsResponse = try await api.request(
            path: "/personal-watchlists/shares/\(shareId)/matches",
            token: token
        )
        return response.results
    }
}
