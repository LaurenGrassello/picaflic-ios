import SwiftUI

struct MessageComposeView: View {
    let recipient: FriendUser
    let token: String
    var existingMessage: Message? = nil

    private let service = MessageService()

    @Environment(\.dismiss) private var dismiss

    @State private var threadMessages: [Message] = []
    @State private var messageBody: String = ""
    @State private var subject: String = ""
    @State private var isSending = false
    @State private var isLoading = false
    @State private var isReplying = false
    @State private var errorMessage: String? = nil

    var isReply: Bool { existingMessage != nil || !threadMessages.isEmpty }

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 0) {

                // Envelope header
                ZStack {
                    Image("EnvelopeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)

                    Text(isReply ? "" : "New Message")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color("BrandTeal"))
                        .rotationEffect(.degrees(-8))
                        .fixedSize()
                        .offset(y: -8)
                }
                .frame(height: 160)
                .padding(.top, 8)

                // Unified message card
                VStack(spacing: 0) {

                    if isLoading {
                        ProgressView()
                            .tint(Color("BrandSand"))
                            .padding(32)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {

                                // Compose area — shown when replying or new message
                                if isReplying || !isReply {
                                    // New message header rows
                                    if !isReply {
                                        messageHeaderRow(
                                            label: "To:",
                                            value: "@\(recipient.display_name)",
                                            tinted: true
                                        )
                                        Divider().background(Color.white.opacity(0.1))
                                        messageHeaderRow(
                                            label: "From:",
                                            value: "You",
                                            tinted: false
                                        )
                                        Divider().background(Color.white.opacity(0.1))
                                        // Subject field for new messages
                                        HStack {
                                            Text("Subject:")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white.opacity(0.7))
                                                .frame(width: 80, alignment: .leading)
                                            TextField("", text: $subject)
                                                .foregroundStyle(.white)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color("BrandTeal").opacity(0.35))
                                        Divider().background(Color.white.opacity(0.1))
                                    } else {
                                        // Reply header
                                        HStack {
                                            Text("Replying to \(recipient.display_name)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color("BrandTeal"))
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color("BrandTeal").opacity(0.15))
                                        Divider().background(Color.white.opacity(0.1))
                                    }

                                    // Compose text area
                                    TextEditor(text: $messageBody)
                                        .foregroundStyle(.white)
                                        .scrollContentBackground(.hidden)
                                        .background(Color("BrandSand").opacity(0.08))
                                        .frame(minHeight: 120)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)

                                    if let error = errorMessage {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(Color("BrandRust"))
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 4)
                                    }

                                    Divider().background(Color.white.opacity(0.1))
                                }

                                // Send / Reply button row
                                HStack {
                                    if isReply && !isReplying {
                                        // Show reply button when not yet replying
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isReplying = true
                                            }
                                        } label: {
                                            Text("Reply")
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(Color("BrandTeal"))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        // Cancel reply
                                        if isReplying {
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isReplying = false
                                                    messageBody = ""
                                                }
                                            } label: {
                                                Text("Cancel")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.white.opacity(0.5))
                                                    .padding(.vertical, 14)
                                                    .padding(.horizontal, 20)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Spacer()

                                        // Send button
                                        Button {
                                            Task { await sendMessage() }
                                        } label: {
                                            Group {
                                                if isSending {
                                                    ProgressView().tint(Color("BrandTeal"))
                                                } else {
                                                    Text("Send")
                                                        .font(.headline.weight(.bold))
                                                        .foregroundStyle(Color("BrandTeal"))
                                                }
                                            }
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 20)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(
                                            messageBody.trimmingCharacters(in: .whitespaces).isEmpty ||
                                            (!isReply && subject.trimmingCharacters(in: .whitespaces).isEmpty) ||
                                            isSending
                                        )
                                    }
                                }
                                .background(Color("BrandSand").opacity(0.1))

                                // Thread messages — newest first
                                if !threadMessages.isEmpty {
                                    ForEach(threadMessages.reversed()) { message in
                                        Divider()
                                            .background(Color.white.opacity(0.15))
                                            .padding(.horizontal, 16)

                                        threadMessageBlock(message)
                                    }
                                }
                            }
                        }
                    }
                }
                .background(Color("BrandSand").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(recipient.display_name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadThread() }
        .onAppear {
            if let msg = existingMessage {
                subject = msg.subject.hasPrefix("Re: ") ? msg.subject : "Re: \(msg.subject)"
            }
            // Auto open reply mode if coming from a received message
            if existingMessage != nil {
                isReplying = false
            }
        }
    }

    // MARK: - Header Row

    private func messageHeaderRow(label: String, value: String, tinted: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tinted ? Color("BrandTeal").opacity(0.35) : Color("BrandSand").opacity(0.15))
    }

    // MARK: - Thread Message Block

    private func threadMessageBlock(_ message: Message) -> some View {
        let isMine = message.sender_id != recipient.id

        return VStack(spacing: 0) {
            // From row
            HStack {
                Text(isMine ? "From: You" : "From: \(message.sender_name)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isMine ? Color("BrandGold") : Color("BrandTeal"))
                Spacer()
                Text(formattedDate(message.created_at))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isMine
                    ? Color("BrandGold").opacity(0.1)
                    : Color("BrandTeal").opacity(0.1)
            )

            // Body
            Text(message.body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("BrandSand").opacity(0.06))
        }
    }

    // MARK: - Helpers

    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: dateString) else { return "" }
        let display = DateFormatter()
        display.dateStyle = .none
        display.timeStyle = .short
        return display.string(from: date)
    }

    // MARK: - Data

    private func loadThread() async {
        isLoading = true
        do {
            threadMessages = try await service.fetchThread(
                token: token,
                userId: recipient.id
            )
        } catch {
            print("LOAD THREAD ERROR:", error)
        }
        isLoading = false
    }

    private func sendMessage() async {
        let bodyTrimmed = messageBody.trimmingCharacters(in: .whitespaces)
        guard !bodyTrimmed.isEmpty else { return }

        let subjectToSend: String
        if isReply {
            subjectToSend = threadMessages.first.map {
                $0.subject.hasPrefix("Re: ") ? $0.subject : "Re: \($0.subject)"
            } ?? subject
        } else {
            subjectToSend = subject.trimmingCharacters(in: .whitespaces)
        }

        isSending = true
        errorMessage = nil

        do {
            try await service.sendMessage(
                token: token,
                recipientId: recipient.id,
                subject: subjectToSend,
                body: bodyTrimmed
            )
            messageBody = ""
            isReplying = false
            await loadThread()
        } catch {
            errorMessage = "Couldn't send message."
        }

        isSending = false
    }
}
