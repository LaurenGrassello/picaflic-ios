import Foundation
import Combine

final class AuthStore: ObservableObject {
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var currentUser: User?

    private let accessTokenKey = "picaflic.accessToken"
    private let refreshTokenKey = "picaflic.refreshToken"

    init() {
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    var isLoggedIn: Bool {
        accessToken != nil
    }

    func saveAuth(_ auth: AuthResponse) {
        accessToken = auth.token
        refreshToken = auth.refresh_token

        UserDefaults.standard.set(auth.token, forKey: accessTokenKey)
        UserDefaults.standard.set(auth.refresh_token, forKey: refreshTokenKey)
    }
    
    func save(_ auth: AuthResponse) {
        accessToken = auth.token
        refreshToken = auth.refresh_token
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil

        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
