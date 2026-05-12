import SwiftUI

struct ContentView: View {
    @AppStorage("show_welcome_onboarding") private var showWelcomeOnboarding = false
    @AppStorage("show_streaming_onboarding") private var showStreamingOnboarding = false
    @AppStorage("onboarding_username") private var onboardingUsername = ""

    @StateObject private var authStore = AuthStore()
    @StateObject private var inboxStore = InboxStore()

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                if showWelcomeOnboarding {
                    WelcomeView(username: onboardingUsername.isEmpty ? "User" : onboardingUsername)
                        .environmentObject(authStore)
                } else if showStreamingOnboarding {
                    StreamingServicesSelectionView(
                        isOnboarding: true,
                        onFinished: {
                            showWelcomeOnboarding = false
                            showStreamingOnboarding = false
                        }
                    )
                    .environmentObject(authStore)
                } else {
                    MainTabView()
                        .environmentObject(authStore)
                        .environmentObject(inboxStore)
                }
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
