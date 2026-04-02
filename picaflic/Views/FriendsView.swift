import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)

                    Text("Friends")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))

                    Text("Search and add friends here.")
                        .foregroundStyle(Color("BrandSand").opacity(0.85))
                }
                .padding()
            }
        }
    }
}

#Preview {
    FriendsView()
}
