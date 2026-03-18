import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let display_name: String
    let services: [String]
}

struct AuthResponse: Decodable {
    let token: String
    let refresh_token: String
    let expires_in: Int
}
