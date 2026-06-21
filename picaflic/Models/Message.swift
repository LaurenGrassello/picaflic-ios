import Foundation

struct Message: Decodable, Identifiable, Equatable {
    let id: Int
    let subject: String
    let body: String
    let read_at: String?
    let created_at: String
    let sender_id: Int
    let sender_name: String
    let recipient_id: Int?
    let recipient_name: String?
    let other_user_id: Int?

    var isUnread: Bool { read_at == nil }
}

struct MessagesResponse: Decodable {
    let results: [Message]
}
