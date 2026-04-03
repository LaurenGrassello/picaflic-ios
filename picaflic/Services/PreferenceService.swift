import Foundation

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
}
