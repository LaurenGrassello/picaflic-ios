import Foundation

final class InboxService {
    private let api = APIClient.shared
    private let friendsService = FriendsService()
    private let messageService = MessageService()
    private let personalWatchlistService = PersonalWatchlistService()

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

    func fetchPersonalWatchlistShares(token: String) async throws -> [PersonalWatchlistShare] {
        try await personalWatchlistService.fetchReceivedShares(token: token)
    }

    func fetchCounts(token: String) async throws -> InboxCounts {
        async let friendsResponse = friendsService.fetchFriends(token: token)
        async let watchlistInvites = fetchWatchlistInvites(token: token)
        async let unreadCount = messageService.unreadCount(token: token)
        async let watchlistShares = fetchPersonalWatchlistShares(token: token)

        let friends = try await friendsResponse
        let invites = try await watchlistInvites
        let unread = try await unreadCount
        let shares = try await watchlistShares

        return InboxCounts(
            friendRequests: friends.pending_received.count,
            watchlistInvites: invites.count,
            unreadMessages: unread,
            watchlistShares: shares.filter { $0.status == "pending" }.count
        )
    }
}
