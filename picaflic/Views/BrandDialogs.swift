import SwiftUI

// MARK: - Action list (replaces native Menu / action sheets)

struct BrandActionSheetOption: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    var isDestructive: Bool = false
    let action: () -> Void
}

struct BrandActionSheet: View {
    let title: String
    let options: [BrandActionSheetOption]
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        option.action()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 22)
                            Text(option.title)
                                .font(.body.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(option.isDestructive ? Color("BrandRust") : Color("BrandGold"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("BrandSand"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(Color("BrandCharcoal"))
        .presentationDetents([.height(150 + CGFloat(options.count) * 62)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color("BrandCharcoal"))
    }
}

// MARK: - Text prompt (replaces native .alert with a TextField)

struct BrandRenameSheet: View {
    let title: String
    @State var name: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Watchlist name", text: $name)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                    Button {
                        onSave(name.trimmingCharacters(in: .whitespaces))
                    } label: {
                        Text("Save")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("BrandGold"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Color("BrandSand"))
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationBackground(Color("BrandCharcoal"))
    }
}

// MARK: - Confirm (replaces native .confirmationDialog)

struct BrandConfirmDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    var isDestructive: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            Image(systemName: isDestructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(isDestructive ? Color("BrandRust") : Color("BrandGold"))
                .padding(.top, 4)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isDestructive ? Color("BrandRust") : Color("BrandGold"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color("BrandSand"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color("BrandCharcoal"))
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color("BrandCharcoal"))
    }
}
