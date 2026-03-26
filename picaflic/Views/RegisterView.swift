import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    private let authService = AuthService()

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 24)

                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)

                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color("BrandSand"))

                    Text("Start discovering what to watch faster.")
                        .font(.subheadline)
                        .foregroundStyle(Color("BrandSand").opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    TextField("", text: $displayName, prompt: Text("Display Name").foregroundColor(Color("BrandSand").opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("BrandSand").opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    TextField("", text: $email, prompt: Text("Email").foregroundColor(Color("BrandSand").opacity(0.7)))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("BrandSand").opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color("BrandSand").opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("BrandSand").opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(Color("BrandRust"))
                        .font(.footnote)
                        .padding(.horizontal, 24)
                }

                Button(action: {
                    Task {
                        await register()
                    }
                }) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color("BrandGold"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .disabled(isLoading)

                Button("Back to Login") {
                    dismiss()
                }
                .fontWeight(.medium)
                .foregroundStyle(Color("BrandTeal"))

                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(" ")
            }
        }
    }

    private func register() async {
        errorMessage = ""
        isLoading = true

        do {
            try await authService.register(
                email: email,
                password: password,
                displayName: displayName,
                services: []
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    RegisterView()
}
