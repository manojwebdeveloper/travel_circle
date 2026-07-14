import AuthenticationServices
import SwiftUI

struct AccountDeletionView: View {
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var acknowledged = false
    @State private var deleted = false

    var body: some View {
        List {
            Section {
                Label("This permanently deletes your Harbor account", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(HarborColors.signalRed)

                Text("Your profile, circle memberships, invitations you created and circles you own will be removed. Location sharing stops immediately.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Before deleting") {
                Label("Apple requires a fresh sign-in before account deletion.", systemImage: "apple.logo")
                Label("Any App Store subscription must be managed separately in Apple Settings.", systemImage: "creditcard")
                Label("This action cannot be undone.", systemImage: "arrow.uturn.backward.slash")
            }

            Section {
                Toggle("I understand that my account and circle data will be permanently deleted.", isOn: $acknowledged)
            }

            Section {
                SignInWithAppleButton(.continue) { request in
                    authSession.prepareAccountDeletionRequest(request)
                } onCompletion: { result in
                    Task { @MainActor in
                        deleted = await authSession.completeAccountDeletion(result)
                        if deleted {
                            dismiss()
                        }
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(Capsule())
                .disabled(!acknowledged || authSession.isBusy)

                if authSession.isBusy {
                    ProgressView("Deleting your account…")
                }
            } footer: {
                Text("The button re-authenticates with Apple, revokes Harbor’s Apple token and securely asks Firebase to delete your account data.")
            }

            if let errorMessage = authSession.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(HarborColors.signalRed)
                }
            }
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(authSession.isBusy)
    }
}
