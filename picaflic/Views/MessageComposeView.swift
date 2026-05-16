import SwiftUI

struct MessageComposeView: View {
    let recipient: FriendUser
    let token: String
    var existingMessage: Message? = nil // if set, shows reply mode
    var onDismiss: () -> Void

    private let service = MessageService()

    @State private var subject: String = ""
    @State private var messageBody: String = ""
    @State private var isSending = false
    @State private var errorMessage: String? = nil
    @State private var didSend = false

    var isReply: Bool { existingMessage != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Envelope header
                    ZStack {
                        Image("Message_V2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)

                        Text(isReply ? "Reply" : "New Message")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color("BrandTeal"))
                            .rotationEffect(.degrees(-4))
                            .offset(y: -8)
                    }
                    .frame(height: 140)
                    .padding(.top, 8)

                    // Form
                    VStack(spacing: 0) {
                        // To
                        formRow(label: "To:") {
                            Text("@\(recipient.display_name)")
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color("BrandTeal").opacity(0.25))

                        Divider().background(Color.white.opacity(0.1))

                        // From — auto-filled, display only
                        formRow(label: "From:") {
                            Text("You")
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Subject
                        formRow(label: "Subject:") {
                            TextField("", text: $subject)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .background(Color("BrandTeal").opacity(0.25))

                        Divider().background(Color.white.opacity(0.1))

                        // Body
                        TextEditor(text: $messageBody)
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 160)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .background(Color("BrandSand").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color("BrandRust"))
                            .padding(.top, 8)
                    }

                    Spacer()

                    // Send / Reply button
                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Group {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text(isReply ? "Reply" : "Send")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandTeal"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty ||
                              messageBody.trimmingCharacters(in: .whitespaces).isEmpty ||
                              isSending)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(Color("BrandSand"))
                }
            }
            .onAppear {
                if let msg = existingMessage {
                    subject = msg.subject.hasPrefix("Re: ") ? msg.subject : "Re: \(msg.subject)"
                }
            }
        }
        .presentationDetents([.large])
    }

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("BrandTeal"))
                .frame(width: 70, alignment: .leading)
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sendMessage() async {
        let subjectTrimmed = subject.trimmingCharacters(in: .whitespaces)
        let bodyTrimmed = messageBody.trimmingCharacters(in: .whitespaces)
        guard !subjectTrimmed.isEmpty, !bodyTrimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil

        do {
            try await service.sendMessage(
                token: token,
                recipientId: recipient.id,
                subject: subjectTrimmed,
                body: bodyTrimmed
            )
            onDismiss()
        } catch {
            errorMessage = "Couldn't send message."
        }

        isSending = false
    }
}
