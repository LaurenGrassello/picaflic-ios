import Foundation

final class InboxService {
    private let api = APIClient.shared
    private let friendsService = FriendsService()

    func fetchWatchlistInvites(token: String) async throws -> [WatchlistInviteItem] {
        let response: WatchlistInvitesResponse = try await api.request(
            path: "/social/watchlist-invites",
            token: token
        )
        return response.results
    }

    func acceptWatchlistInvite(token: String, inviteId: Int) async throws {
        let _: BasicActionResponse = try await api.request(
            path: "/social/watchlist-invites/\(inviteId)/accept",
            method: "POST",
            token: token
        )
    }

    func declineWatchlistInvite(token: String, inviteId: Int) async throws {
        let _: BasicActionResponse = try await api.request(
            path: "/social/watchlist-invites/\(inviteId)/decline",
            method: "POST",
            token: token
        )
    }

    func fetchCounts(token: String) async throws -> InboxCounts {
        async let friendsResponse = friendsService.fetchFriends(token: token)
        async let watchlistInvites = fetchWatchlistInvites(token: token)

        let friends = try await friendsResponse
        let invites = try await watchlistInvites

        return InboxCounts(
            friendRequests: friends.pending_received.count,
            watchlistInvites: invites.count
        )
    }
}
