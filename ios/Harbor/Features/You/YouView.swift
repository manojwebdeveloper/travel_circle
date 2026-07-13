import SwiftUI

struct YouView: View {
    @EnvironmentObject private var appState: AppState
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
                                Text("A")
                                    .font(.title3.bold())
                                    .foregroundStyle(HarborColors.warmAmber)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Alex Harris")
                                .font(.headline)
                            Text("Manage profile")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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

                        ForEach(store.circles) { circle in
                            HStack {
                                Text(circle.name)
                                Spacer()
                                Text(circle.expiresAt == nil ? "Always" : "Temporary")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }

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
                    ForEach(store.circles) { circle in
                        NavigationLink {
                            CircleSummaryView(circle: circle, members: store.members)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(circle.name)
                                Text(circle.kind.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
            }
            .navigationTitle("You")
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 94) }
        }
    }
}

private struct CircleSummaryView: View {
    let circle: HarborCircle
    let members: [HarborMember]

    var body: some View {
        List {
            Section("Circle") {
                LabeledContent("Type", value: circle.kind.rawValue)
                if let expiresAt = circle.expiresAt {
                    LabeledContent("Expires", value: expiresAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            Section("Members") {
                ForEach(members.filter { circle.memberIDs.contains($0.id) }) { member in
                    HStack(spacing: 12) {
                        HarborAvatar(member: member, size: 36)
                        Text(member.name)
                        Spacer()
                        Text(member.presence.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(circle.name)
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
                LabeledContent("Location history", value: "2 days")
                Button("Delete location history") { }
                Button("Export account data") { }
            }
            Section("Account") {
                Button("Delete account", role: .destructive) { }
            }
        }
        .navigationTitle("Privacy & data")
    }
}

private struct PlaceholderSettingsView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer",
            description: Text("This native flow is scaffolded and will be connected to its service in the next implementation milestone.")
        )
        .navigationTitle(title)
    }
}
