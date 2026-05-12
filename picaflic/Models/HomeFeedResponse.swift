import Foundation

struct HomeFeedMeta: Decodable {
    let limit: Int
    let offset: Int
    let count: Int
    let has_more: Bool
}

struct HomeFeedResponse: Decodable {
    let results: [FeedItem]
    let meta: HomeFeedMeta
}
