import Foundation

final class FriendsService {
    private let api = APIClient.shared

    func fetchFriends(token: String) async throws -> FriendsResponse {
        try await api.request(
            path: "/social/friends",
            token: token
        )
    }

    func searchUsers(token: String, query: String) async throws -> [UserSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        let response: UserSearchResponse = try await api.request(
            path: "/social/users/search?q=\(encodedQuery)",
            token: token
        )
        return response.results
    }

    func sendFriendRequest(token: String, userId: Int) async throws {
        let _: FriendActionResponse = try await api.request(
            path: "/social/friends/request/\(userId)",
            method: "POST",
            token: token
        )
    }

    func acceptFriend(token: String, userId: Int) async throws {
        let _: FriendActionResponse = try await api.request(
            path: "/social/friends/accept/\(userId)",
            method: "POST",
            token: token
        )
    }

    func declineFriend(token: String, userId: Int) async throws {
        let _: FriendActionResponse = try await api.request(
            path: "/social/friends/\(userId)",
            method: "DELETE",
            token: token
        )
    }
}

struct FriendActionResponse: Decodable {
    let ok: Bool?
    let status: String?
    let error: String?
}
