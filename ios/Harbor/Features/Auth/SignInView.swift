import AuthenticationServices
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
                SignInWithAppleButton(.signIn) { request in
                    authSession.prepareSignInRequest(request)
                } onCompletion: { result in
                    Task { @MainActor in
                        await authSession.completeSignIn(result)
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(Capsule())
                .disabled(authSession.isBusy)

                if authSession.isBusy {
                    ProgressView("Signing in securely…")
                        .font(.footnote)
                }

                if let errorMessage = authSession.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(HarborColors.signalRed)
                        .multilineTextAlignment(.center)
                }

                Text("Apple may share your name and email only the first time you sign in. Harbor never receives your Apple password.")
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
