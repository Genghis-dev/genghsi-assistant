import SwiftUI

struct VoiceNoteView: View {
    @State private var isRecording = false
    @State private var savedToNotes = false

    private let speech = SpeechRecognizer.shared
    private let store = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Voice Note")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                if !speech.transcript.isEmpty {
                    Button(action: saveToNotes) {
                        HStack(spacing: 4) {
                            Image(systemName: savedToNotes ? "checkmark" : "note.text.badge.plus")
                                .font(.system(size: 11))
                            Text(savedToNotes ? "Saved" : "Save to Notes")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(savedToNotes ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            Spacer()

            if !speech.isAuthorized {
                VStack(spacing: 8) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("Speech recognition not authorized")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Enable in System Settings → Privacy")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            } else {
                // Transcript area
                if speech.transcript.isEmpty && !speech.isListening {
                    VStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("Tap to start recording")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    ScrollView {
                        Text(speech.transcript.isEmpty ? "Listening..." : speech.transcript)
                            .font(.system(size: 13))
                            .foregroundStyle(speech.transcript.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 8)
                }
            }

            Spacer()

            // Record button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(speech.isListening ? Color.red : Color.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: (speech.isListening ? Color.red : Color.blue).opacity(0.4), radius: 8)

                    if speech.isListening {
                        // Pulsing animation
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                            .frame(width: 68, height: 68)
                            .scaleEffect(speech.isListening ? 1.2 : 1.0)
                            .opacity(speech.isListening ? 0 : 1)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: speech.isListening)
                    }

                    Image(systemName: speech.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(!speech.isAuthorized)
            .padding(.bottom, 16)
        }
        .frame(width: 260, height: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }

    private func toggleRecording() {
        if speech.isListening {
            speech.stopListening()
        } else {
            savedToNotes = false
            speech.startListening()
        }
    }

    private func saveToNotes() {
        guard !speech.transcript.isEmpty else { return }
        _ = store.createNote(content: speech.transcript)
        savedToNotes = true
    }
}
