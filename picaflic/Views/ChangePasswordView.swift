import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 24) {
                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .padding(.top, 24)

                Text("Change Password")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))

                VStack(spacing: 12) {
                    SecureField("Current password", text: $currentPassword)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("New password", text: $newPassword)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Confirm new password", text: $confirmPassword)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color("BrandRust"))
                    }

                    if let success = successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(Color("BrandTeal"))
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await save() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Password")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandGold"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(
                    currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty ||
                    isSaving
                )
                .padding(.horizontal, 24)
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard let token = authStore.accessToken else { return }

        guard newPassword == confirmPassword else {
            errorMessage = "New passwords don't match."
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            struct Body: Encodable {
                let current_password: String
                let new_password: String
            }
            struct Response: Decodable { let ok: Bool? }
            let _: Response = try await api.request(
                path: "/profile/password",
                method: "PUT",
                token: token,
                body: Body(current_password: currentPassword, new_password: newPassword)
            )
            successMessage = "Password updated!"
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            errorMessage = "Couldn't update password. Check your current password."
        }

        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthStore())
    }
}
