import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore()
    @StateObject private var inboxStore = InboxStore()

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
                    .environmentObject(authStore)
                    .environmentObject(inboxStore)
            } else {
                LoginView()
                    .environmentObject(authStore)
            }
        }
        .task(id: authStore.isLoggedIn) {
            if authStore.isLoggedIn {
                await inboxStore.refresh(token: authStore.accessToken)
            } else {
                inboxStore.clear()
            }
        }
    }
}

#Preview {
    ContentView()
}
