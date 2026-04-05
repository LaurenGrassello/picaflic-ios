import Foundation

struct CreateWatchlistRequest: Encodable {
    let name: String
    let member_ids: [Int]
}

struct CreateWatchlistResponse: Decodable {
    let ok: Bool
    let watchlist: CreatedWatchlist
}

struct CreatedWatchlist: Decodable {
    let id: Int
    let name: String
    let created_by: Int
    let member_count: Int
}
