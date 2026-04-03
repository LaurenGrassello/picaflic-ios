import Foundation

struct FeedItem: Decodable, Identifiable, Hashable {
    let id: Int?
    let tmdb_id: Int
    let is_tv: Int
    let title: String
    let popularity: Double?
    let release_date: String?
    let poster_path: String?

    var localId: Int? { id }
    var isTV: Bool { is_tv == 1 }

    var posterURL: URL? {
        guard let poster_path, !poster_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }
}

struct FeedResultsResponse: Decodable {
    let results: [FeedItem]
}
