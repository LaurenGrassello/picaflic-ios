import Foundation

struct Message: Decodable, Identifiable {
    let id: Int
    let subject: String
    let body: String
    let read_at: String?
    let created_at: String
    let sender_id: Int
    let sender_name: String

    var isUnread: Bool { read_at == nil }
}

struct MessagesResponse: Decodable {
    let results: [Message]
}
