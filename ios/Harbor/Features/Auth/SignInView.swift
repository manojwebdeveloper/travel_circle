import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(HarborColors.brandGradient)
                    .frame(width: 124, height: 124)
                    .shadow(color: HarborColors.calmTeal.opacity(0.22), radius: 24, y: 12)
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text("Welcome to Harbor")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                Text("Sign in to create trusted circles, accept invitations and control who can see your location.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 26)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    Task { @MainActor in
                        await authSession.continueWithoutAppleForTesting()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 19, weight: .semibold))
                        Text("Sign in with Apple")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(authSession.isBusy)

                if authSession.isBusy {
                    ProgressView("Opening Harbor…")
                        .font(.footnote)
                }

                if let errorMessage = authSession.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(HarborColors.signalRed)
                        .multilineTextAlignment(.center)
                }

                Text("Temporary test mode: this button currently skips the Apple authentication sheet and creates a private Firebase test session. The Apple Sign-In implementation remains in the project for later activation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct FirebaseSetupRequiredView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Firebase setup required", systemImage: "flame.fill")
        } description: {
            Text("Add GoogleService-Info.plist to ios/Harbor/Resources, generate the Xcode project again and rebuild the app.")
        } actions: {
            Text("See docs/firebase-testing-setup.md in the repository.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(HarborColors.calmTeal)
        }
    }
}
