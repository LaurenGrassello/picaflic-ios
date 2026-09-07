import Foundation

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

    func setPreference(token: String, movieId: Int, status: String) async throws -> PreferenceResponse {
        let body = PreferenceRequest(movie_id: movieId, status: status)

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
