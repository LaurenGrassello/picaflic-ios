import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore()
    private let authService = AuthService()

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                BrowseView()
                    .environmentObject(authStore)
            } else {
                LoginView()
                    .environmentObject(authStore)
            }
        }
        .task {
            await loadUserIfNeeded()
        }
    }

    private func loadUserIfNeeded() async {
        guard authStore.currentUser == nil,
              let token = authStore.accessToken else {
            return
        }

        do {
            let user = try await authService.me(token: token)
            authStore.currentUser = user
        } catch {
            authStore.clear()
        }
    }
}

#Preview {
    ContentView()
}
