import Foundation

// PreferenceRequest / PreferenceResponse are defined elsewhere in the project
// (unchanged): { movie_id: Int, status: String } for the request,
// { ok: Bool, movie_id: Int, status: String } for the response.

struct LikedMovie: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let tmdb_id: Int?
    let poster_path: String?

    var posterURL: URL? {
        guard let poster_path, !poster_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }
}

final class PreferenceService {
    private let api = APIClient.shared

    /// Sets a like/dislike/none preference for a movie.
    ///
    /// If `movie.localId` is already known, we send `movie_id` directly — same
    /// as before. If it's `nil` (a raw search result never saved locally), we
    /// send the TMDB fields instead, and the backend will find or create the
    /// local `movies` row before recording the preference — same pattern as
    /// the "add to watchlist" fix.
    func setPreference(token: String, movie: FeedItem, status: String) async throws -> PreferenceResponse {
        struct Body: Encodable {
            let movie_id: Int?
            let tmdb_id: Int?
            let title: String?
            let poster_path: String?
            let genre_ids: String?
            let release_date: String?
            let popularity: Double?
            let status: String
        }

        let body: Body
        if let localId = movie.localId {
            body = Body(
                movie_id: localId,
                tmdb_id: nil,
                title: nil,
                poster_path: nil,
                genre_ids: nil,
                release_date: nil,
                popularity: nil,
                status: status
            )
        } else {
            body = Body(
                movie_id: nil,
                tmdb_id: movie.tmdb_id,
                title: movie.title,
                poster_path: movie.poster_path,
                genre_ids: movie.genre_ids,
                release_date: movie.release_date,
                popularity: movie.popularity,
                status: status
            )
        }

        let response: PreferenceResponse = try await api.request(
            path: "/social/preferences",
            method: "POST",
            token: token,
            body: body
        )
        return response
    }

    func fetchLikedMovies(token: String) async throws -> [LikedMovie] {
        struct Response: Decodable {
            let results: [LikedMovie]
        }
        let response: Response = try await api.request(
            path: "/social/preferences/liked",
            token: token
        )
        return response.results
    }

    func fetchDislikedMovieIds(token: String) async throws -> Set<Int> {
        struct DislikedResult: Decodable {
            let id: Int
        }
        struct Response: Decodable {
            let results: [DislikedResult]
        }
        let response: Response = try await api.request(
            path: "/social/preferences/disliked",
            token: token
        )
        return Set(response.results.map { $0.id })
    }
}
