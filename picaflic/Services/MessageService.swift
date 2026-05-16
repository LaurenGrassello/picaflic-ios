import Foundation

final class MessageService {
    private let api = APIClient.shared

    func fetchMessages(token: String) async throws -> [Message] {
        let response: MessagesResponse = try await api.request(
            path: "/messages",
            token: token
        )
        return response.results
    }

    func sendMessage(token: String, recipientId: Int, subject: String, body: String) async throws {
        struct Body: Encodable {
            let recipient_id: Int
            let subject: String
            let body: String
        }
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await api.request(
            path: "/messages",
            method: "POST",
            token: token,
            body: Body(recipient_id: recipientId, subject: subject, body: body)
        )
    }

    func unreadCount(token: String) async throws -> Int {
        struct CountResponse: Decodable { let count: Int }
        let response: CountResponse = try await api.request(
            path: "/messages/unread-count",
            token: token
        )
        return response.count
    }
}
