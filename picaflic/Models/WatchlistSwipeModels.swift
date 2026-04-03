import Foundation

struct WatchlistSwipeRequest: Encodable {
    let movie_id: Int
    let status: String
}

struct MatchedUser: Decodable, Identifiable, Hashable {
    let id: Int
    let display_name: String
    let email: String
}

struct WatchlistSwipeResponse: Decodable {
    let ok: Bool
    let match: Bool
    let matched_users: [MatchedUser]
    let match_count: Int
    let status: String
}
