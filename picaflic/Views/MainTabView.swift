import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            WatchlistsView()
                .tabItem {
                    Label("Watchlists", systemImage: "person.2")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "magnifyingglass")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthStore())
}
