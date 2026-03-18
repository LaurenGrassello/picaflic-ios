import Foundation

final class FeedService {
    private let api = APIClient.shared

    func fetchForYou(
        token: String,
        query: String? = nil,
        type: String = "all"
    ) async throws -> [FeedItem] {
        var path = "/feed/for-you?limit=40&page=1&type=\(type)"

        if let query, !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            path += "&q=\(encoded)"
        }

        let response: [FeedItem] = try await api.request(
            path: path,
            token: token
        )
        return response
    }
}
