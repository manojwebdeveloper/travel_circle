import SwiftUI

struct YouView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var circleService: CircleService
    @ObservedObject var store: PreviewStore

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
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            appState.isSharingPaused ? "Location sharing is paused" : "Location sharing is on",
                            systemImage: appState.isSharingPaused ? "pause.circle.fill" : "location.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(appState.isSharingPaused ? HarborColors.slate : HarborColors.safeGreen)

                        Text("Shared circle access is controlled by your Firebase memberships. Real background location sync will be connected in the next milestone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button(appState.isSharingPaused ? "Resume sharing" : "Pause sharing") {
                            withAnimation(.snappy) {
                                appState.isSharingPaused.toggle()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(appState.isSharingPaused ? HarborColors.calmTeal : HarborColors.slate)
                    }
                    .padding(.vertical, 8)
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
                    NavigationLink("Location sharing") { PlaceholderSettingsView(title: "Location sharing") }
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
                NavigationLink("Who can see my location") { PlaceholderSettingsView(title: "Visibility") }
                NavigationLink("Active sharing sessions") { PlaceholderSettingsView(title: "Active sessions") }
                LabeledContent("New sessions expire", value: "Ask each time")
            }

            Section("Your data") {
                LabeledContent("Location history", value: "Not connected")
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
