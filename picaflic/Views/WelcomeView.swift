import SwiftUI

struct WelcomeView: View {
    let username: String
    
    @State private var pulseGlow = false

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    Image("LogoEyeV2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54)
                        .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 8)
                        .padding(.top, 28)

                    Text("Welcome")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color("BrandTeal"))
                        .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: 4)

                    Text("Here is your rental card!")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 3)

                    Button {
                        UserDefaults.standard.set(false, forKey: "show_welcome_onboarding")
                        UserDefaults.standard.set(true, forKey: "show_streaming_onboarding")
                    } label: {
                        rentalCard
                            .shadow(
                                color: Color("BrandTeal").opacity(pulseGlow ? 0.75 : 0.35),
                                radius: pulseGlow ? 24 : 12,
                                x: 0,
                                y: 0
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 26)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 26)

                    Text("Tap your rental card to get started")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 22) {
                        Text("Select your streaming services,\nrefine what you’re looking for.\nThen we search everything for you.")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .lineSpacing(4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Browse solo anytime,")
                                .foregroundStyle(.white.opacity(0.9))

                            Text("or start a watchlist with friends")
                                .foregroundStyle(Color("BrandTeal"))

                            Text("and swipe together to agree.")
                                .foregroundStyle(Color("BrandGold"))
                        }
                        .font(.title3)
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
    }

    private var rentalCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("BrandTeal").opacity(0.65), lineWidth: 1.2)
                )
                .shadow(color: Color("BrandTeal").opacity(0.65), radius: 18, x: 0, y: 0)
                .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 6)

            VStack(spacing: 20) {
                Image("TealLetterLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230)
                    .padding(.top, 22)

                VStack(spacing: 0) {
                    HStack {
                        Text(username.isEmpty ? "(Username)" : username)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.82))

                        Spacer()
                    }
                    .padding(.horizontal, 26)
                    .frame(height: 62)
                    .background(Color("BrandSand").opacity(0.85))

                    Rectangle()
                        .fill(Color("BrandGold"))
                        .frame(height: 28)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .frame(height: 230)
    }
}
