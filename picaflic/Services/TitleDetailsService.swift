import Foundation

final class TitleDetailsService {
    private let api = APIClient.shared

    func fetchDetails(token: String, kind: String, tmdbId: Int) async throws -> TitleDetails {
        let response: TitleDetails = try await api.request(
            path: "/titles/\(kind)/\(tmdbId)",
            token: token
        )
        return response
    }
}
