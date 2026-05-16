import Foundation

struct WatchlistSummary: Decodable, Identifiable {
    let id: Int
    let name: String
    let created_by: Int
    let member_count: Int
    let member_names: [String]
}

struct WatchlistsResponse: Decodable {
    let results: [WatchlistSummary]
}
