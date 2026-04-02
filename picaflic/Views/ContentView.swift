import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore()

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
                    .environmentObject(authStore)
            } else {
                LoginView()
                    .environmentObject(authStore)
            }
        }
    }
}

#Preview {
    ContentView()
}
