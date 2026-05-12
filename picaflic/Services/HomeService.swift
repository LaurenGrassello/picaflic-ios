import Foundation

final class HomeService {
    private let api = APIClient.shared

    func fetchHomeFeed(token: String, limit: Int = 20, offset: Int = 0) async throws -> HomeFeedResponse {
        let response: HomeFeedResponse = try await api.request(
            path: "/feed/for-you?limit=\(limit)&offset=\(offset)",
            token: token
        )
        return response
    }

    func searchMovies(token: String, query: String) async throws -> [FeedItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        let response: [FeedItem] = try await api.request(
            path: "/search?q=\(encodedQuery)",
            token: token
        )
        return response
    }
}
