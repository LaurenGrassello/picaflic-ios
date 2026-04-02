import SwiftUI

struct HomeView: View {
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

                    Text("Home")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))

                    Text("Solo movie discovery will live here.")
                        .foregroundStyle(Color("BrandSand").opacity(0.85))
                }
                .padding()
            }
        }
    }
}

#Preview {
    HomeView()
}
