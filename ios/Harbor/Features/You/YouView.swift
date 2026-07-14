import SwiftUI

struct YouView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var circleService: CircleService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(HarborColors.warmAmber.opacity(0.18))
                            .frame(width: 58, height: 58)
                            .overlay {
                                Text(initials)
                                    .font(.title3.bold())
                                    .foregroundStyle(HarborColors.warmAmber)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(authSession.displayName)
                                .font(.headline)
                            if let emailAddress = authSession.emailAddress, !emailAddress.isEmpty {
                                Text(emailAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Signed in with Apple")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Location sharing") {
                    Label("Location service not connected", systemImage: "location.slash.fill")
                        .font(.headline)
                        .foregroundStyle(HarborColors.warmAmber)

                    Text("This test milestone stores real accounts, circles and memberships. It does not upload or display device coordinates yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Your circles") {
                    if circleService.circles.isEmpty {
                        Text("No Firebase circles yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(circleService.circles.prefix(3)) { circle in
                            HStack(spacing: 12) {
                                Image(systemName: circle.kind == .family ? "person.3.fill" : "suitcase.rolling.fill")
                                    .foregroundStyle(circle.kind == .family ? HarborColors.calmTeal : HarborColors.clearSky)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(circle.name)
                                    Text(circle.kind.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    NavigationLink {
                        CircleHubView()
                    } label: {
                        Label("Manage circles and invitations", systemImage: "person.3.sequence.fill")
                    }
                }

                Section("Settings") {
                    NavigationLink("Notifications") { PlaceholderSettingsView(title: "Notifications") }
                    NavigationLink("Privacy & data") { PrivacyDataView() }
                    NavigationLink("Subscription") { PlaceholderSettingsView(title: "Harbor Premium") }
                }

                Section("Support") {
                    NavigationLink("Help & support") { PlaceholderSettingsView(title: "Help & support") }
                    NavigationLink("About Harbor") { PlaceholderSettingsView(title: "About Harbor") }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        authSession.signOut()
                    }
                }
            }
            .navigationTitle("You")
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 94) }
        }
    }

    private var initials: String {
        let components = authSession.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let value = String(components)
        return value.isEmpty ? "H" : value.uppercased()
    }
}

private struct PrivacyDataView: View {
    var body: some View {
        List {
            Section("Visibility") {
                LabeledContent("Circle memberships", value: "Firebase")
                LabeledContent("Location sharing", value: "Not connected")
            }

            Section("Your data") {
                LabeledContent("Location history", value: "No data collected")
                Button("Delete location history") { }
                    .disabled(true)
                Button("Export account data") { }
                    .disabled(true)
            }

            Section("Account") {
                NavigationLink {
                    AccountDeletionView()
                } label: {
                    Text("Delete account")
                        .foregroundStyle(HarborColors.signalRed)
                }
            }
        }
        .navigationTitle("Privacy & data")
    }
}

struct PlaceholderSettingsView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer",
            description: Text("This flow is reserved for the next implementation milestone.")
        )
        .navigationTitle(title)
    }
}
