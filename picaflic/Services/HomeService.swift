import Foundation

final class HomeService {
    private let api = APIClient.shared

    func fetchHomeFeed(token: String) async throws -> [FeedItem] {
        let response: [FeedItem] = try await api.request(
            path: "/feed/for-you",
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
