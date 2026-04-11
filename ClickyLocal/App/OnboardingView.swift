import SwiftUI
import AVFoundation
import Speech

struct OnboardingView: View {
    @State private var microphoneGranted = false
    @State private var speechGranted = false
    @State private var dockerRunning = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "sparkle")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text("Welcome to Genghsi")
                    .font(.system(size: 18, weight: .bold))

                Text("Your private AI companion. Everything runs locally — no data leaves your Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 4) {
                    // Accessibility — must be opened manually
                    PermissionRow(
                        icon: "hand.raised.fill",
                        title: "Accessibility",
                        subtitle: "Open System Settings and toggle Genghsi on",
                        status: .openSettings,
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    )

                    // Microphone — can be auto-detected
                    PermissionRow(
                        icon: "mic.fill",
                        title: "Microphone",
                        subtitle: microphoneGranted ? "Granted" : "For voice notes",
                        status: microphoneGranted ? .granted : .grant,
                        action: requestMicrophone
                    )

                    // Speech — can be auto-detected
                    PermissionRow(
                        icon: "waveform",
                        title: "Speech Recognition",
                        subtitle: speechGranted ? "Granted" : "For on-device transcription",
                        status: speechGranted ? .granted : .grant,
                        action: requestSpeechRecognition
                    )

                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    // Docker
                    PermissionRow(
                        icon: "shippingbox.fill",
                        title: "Docker Model Runner",
                        subtitle: dockerRunning ? "Gemma 4 is ready" : "Start Docker Desktop with Model Runner enabled",
                        status: dockerRunning ? .granted : .grant,
                        action: checkDocker
                    )

                    // Note about Accessibility/Screen Recording
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            Text("Note")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        Text("Accessibility permission requires toggling Genghsi on in System Settings. This can't be auto-detected during development — the app will work once it's enabled.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.06))
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                    // What's inside
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    VStack(spacing: 0) {
                        featureRow(icon: "bubble.left.fill", title: "Chat", subtitle: "Your private AI, runs locally")
                        Divider().opacity(0.3).padding(.horizontal, 12)
                        featureRow(icon: "note.text", title: "Notes", subtitle: "Quick capture, always at hand")
                        Divider().opacity(0.3).padding(.horizontal, 12)
                        featureRow(icon: "pencil.and.outline", title: "Rewrite", subtitle: "Fix your messages, keep your voice")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }

            Divider()
                .padding(.horizontal, 16)

            Button(action: {
                onComplete()
            }) {
                Text("Get Started")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 380, height: 580)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
        .task {
            checkAutoDetectable()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.0))
                checkAutoDetectable()
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.71, green: 0.83, blue: 0.95))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // Only poll permissions that macOS lets us auto-detect
    private func checkAutoDetectable() {
        microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
        checkDocker()
    }

    private func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { microphoneGranted = granted }
        }
    }

    private func requestSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { speechGranted = (status == .authorized) }
        }
    }

    private func checkDocker() {
        Task {
            do {
                guard let url = URL(string: "http://localhost:12434/engines/v1/models") else { return }
                let (_, response) = try await URLSession.shared.data(from: url)
                let isOk = (response as? HTTPURLResponse)?.statusCode == 200
                await MainActor.run { dockerRunning = isOk }
            } catch {
                await MainActor.run { dockerRunning = false }
            }
        }
    }
}

enum PermissionStatus {
    case granted
    case grant
    case openSettings
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let status: PermissionStatus
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(status == .granted ? .green : .blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            switch status {
            case .granted:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.green)
            case .grant:
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            case .openSettings:
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text("Open")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.orange)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
        )
        .onHover { isHovered = $0 }
    }
}
