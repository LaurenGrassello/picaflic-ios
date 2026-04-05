import Foundation

struct FriendUser: Decodable, Identifiable, Hashable {
    let id: Int
    let display_name: String
    let email: String
}

struct FriendsResponse: Decodable {
    let friends: [FriendUser]
    let pending_sent: [FriendUser]
    let pending_received: [FriendUser]
}

struct UserSearchResult: Decodable, Identifiable, Hashable {
    let id: Int
    let display_name: String
    let email: String
    let friendship_status: String
}

struct UserSearchResponse: Decodable {
    let results: [UserSearchResult]
}
