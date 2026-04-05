import Foundation

struct WatchlistInviteItem: Decodable, Identifiable, Hashable {
    let id: Int
    let watchlist_id: Int
    let watchlist_name: String
    let invited_by_user_id: Int
    let invited_by_name: String
    let status: String
}

struct WatchlistInvitesResponse: Decodable {
    let results: [WatchlistInviteItem]
}

struct InboxCounts {
    let friendRequests: Int
    let watchlistInvites: Int

    var total: Int {
        friendRequests + watchlistInvites
    }
}

struct BasicActionResponse: Decodable {
    let ok: Bool?
    let status: String?
    let error: String?
}
