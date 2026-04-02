import SwiftUI

struct VHSMoviePlaceholderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("BrandCharcoal"))

            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)

            VStack(spacing: 14) {
                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 120, height: 70)
                    .overlay(
                        Image("EyeballGraphic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    )

                VStack(spacing: 6) {
                    Text("PIC-A-FLIC")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))
                }

                Spacer()

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("BrandGold"))
                    .frame(width: 130, height: 24)
                    .overlay(
                        Text("Image Unavailable")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    )
                    .padding(.bottom, 18)
            }
            .padding(16)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VHSMoviePlaceholderView()
            .frame(width: 160, height: 220)
    }
}
