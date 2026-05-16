import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var inboxStore: InboxStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: WatchlistsView()
                case 2: FriendsView()
                case 3: ProfileView()
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 70)

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(inboxStore)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, icon: "LogoEyeV2",          label: "Browse")
            tabButton(index: 1, icon: "PlayButton",    label: "Watchlists")
            tabButton(index: 2, icon: "FriendsHeart",  label: "Friends")
            tabButton(index: 3, icon: "Home_Icon",              label: "Home",
                      badge: inboxStore.pendingCount > 0 ? inboxStore.pendingCount : nil)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // frosted glass
                Rectangle()
                    .fill(.ultraThinMaterial)

                // warm gold tint overlay
                Color("BrandGold")
                    .opacity(0.08)

                // top border
                VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color("BrandGold").opacity(0.3))
                    Spacer()
                }
            }
        )
    }

    private func tabButton(index: Int, icon: String, label: String, badge: Int? = nil) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(selectedTab == index ? Color("BrandGold") : Color("BrandSand").opacity(0.5))
                        // template rendering so tint works
                        .colorMultiply(selectedTab == index ? Color("BrandGold") : Color("BrandSand").opacity(0.5))

                    if let badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color("BrandRust"))
                            .clipShape(Circle())
                            .offset(x: 8, y: -6)
                    }
                }

                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selectedTab == index ? Color("BrandGold") : Color("BrandSand").opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environmentObject(InboxStore())
}
