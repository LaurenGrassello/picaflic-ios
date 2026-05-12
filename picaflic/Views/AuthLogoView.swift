import SwiftUI

struct AuthLogoView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color("BrandGold").opacity(0.30))
                .blur(radius: 38)
                .frame(width: 260, height: 260)
                .offset(y: 10)

            Circle()
                .fill(Color("BrandTeal").opacity(0.18))
                .blur(radius: 34)
                .frame(width: 230, height: 230)
                .offset(y: -8)

            Image("LogoEyeV2")
                .resizable()
                .scaledToFit()
                .frame(width: 205)
                .offset(y: -12)

            Image("LogoWordmarkGold")
                .resizable()
                .scaledToFit()
                .frame(width: 460)
                .offset(y: -28)
        }
        .frame(height: 255)
        .shadow(color: Color("BrandGold").opacity(0.45), radius: 16, x: 0, y: 8)
    }
}
