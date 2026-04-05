import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var inboxStore: InboxStore

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
                .badge(inboxStore.pendingCount > 0 ? inboxStore.pendingCount : 0)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(InboxStore())
}
