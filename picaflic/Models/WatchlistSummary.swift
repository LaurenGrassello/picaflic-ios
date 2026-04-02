import Foundation

struct WatchlistSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let created_by: Int
    let member_count: Int
}

struct WatchlistsResponse: Decodable {
    let results: [WatchlistSummary]
}
