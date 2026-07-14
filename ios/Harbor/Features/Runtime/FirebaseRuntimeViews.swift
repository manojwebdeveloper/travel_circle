import SwiftUI

struct FirebaseMapHomeView: View {
    @EnvironmentObject private var circleService: CircleService

    var body: some View {
        NavigationStack {
            Group {
                if let circle = circleService.selectedCircle {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            circleSelector(selected: circle)
                            locationUnavailableCard(circle: circle)
                            memberSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 130)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    noCircleState
                }
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CircleHubView()
                    } label: {
                        Image(systemName: "person.3")
                    }
                }
            }
        }
    }

    private func circleSelector(selected: FirebaseCircleSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(selected.name)
                    .font(.title2.bold())
                Text(selected.kind.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                ForEach(circleService.circles) { circle in
                    Button {
                        circleService.selectCircle(circle.id)
                    } label: {
                        if circle.id == selected.id {
                            Label(circle.name, systemImage: "checkmark")
                        } else {
                            Text(circle.name)
                        }
                    }
                }
            } label: {
                Label("Switch", systemImage: "chevron.up.chevron.down")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.top, 8)
    }

    private func locationUnavailableCard(circle: FirebaseCircleSummary) -> some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(HarborColors.seaGlass.opacity(0.55))
                    .frame(height: 210)

                VStack(spacing: 13) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(HarborColors.calmTeal)
                    Text("Real location sharing is not connected yet")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("This screen is using your real Firebase circle and members. No sample coordinates are being shown.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }
            }

            HStack {
                Label("\(circleService.members.count) members", systemImage: "person.2.fill")
                Spacer()
                if let expiresAt = circle.expiresAt {
                    Label(expiresAt.formatted(date: .abbreviated, time: .shortened), systemImage: "timer")
                } else {
                    Label("No expiry", systemImage: "infinity")
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .harborCard()
    }

    private var memberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circle members")
                .font(.title3.bold())

            if circleService.members.isEmpty {
                ContentUnavailableView(
                    "No members yet",
                    systemImage: "person.badge.plus",
                    description: Text("Create and share an invitation from circle management.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .harborCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(circleService.members.enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(HarborColors.seaGlass)
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Text(initials(for: member.displayName))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(HarborColors.calmTeal)
                                }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(member.displayName)
                                    .font(.headline)
                                Text(member.role.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            HarborStatusPill(
                                text: member.sharingEnabled ? "Sharing enabled" : "Sharing off",
                                color: member.sharingEnabled ? HarborColors.safeGreen : HarborColors.slate
                            )
                        }
                        .padding(.vertical, 13)

                        if index < circleService.members.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
            }
        }
    }

    private var noCircleState: some View {
        ContentUnavailableView {
            Label("Create or join a circle", systemImage: "person.3.sequence.fill")
        } description: {
            Text("Your real Firebase circles will appear here. Harbor does not insert sample families into signed-in accounts.")
        } actions: {
            NavigationLink("Manage circles") {
                CircleHubView()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func initials(for name: String) -> String {
        let characters = name.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(characters)
        return value.isEmpty ? "H" : value.uppercased()
    }
}

struct FirebaseJourneyHomeView: View {
    @EnvironmentObject private var circleService: CircleService

    private var selectedTrip: FirebaseCircleSummary? {
        if let selected = circleService.selectedCircle, selected.kind == .trip {
            return selected
        }
        return circleService.circles.first { $0.kind == .trip }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let trip = selectedTrip {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.name)
                                            .font(.title2.bold())
                                        Text("Temporary trip circle")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    HarborStatusPill(text: "Real Firebase data", color: HarborColors.calmTeal)
                                }

                                if let expiresAt = trip.expiresAt {
                                    Label(
                                        "Ends \(expiresAt.formatted(date: .abbreviated, time: .shortened))",
                                        systemImage: "timer"
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                            }
                            .harborCard()

                            ContentUnavailableView {
                                Label("No active journey yet", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            } description: {
                                Text("Meeting points, ETAs and arrival status need the location and journey service milestone. This build does not substitute hardcoded journey data.")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .harborCard()

                            Text("Members")
                                .font(.title3.bold())

                            ForEach(circleService.members) { member in
                                HStack {
                                    Text(member.displayName)
                                    Spacer()
                                    Text(member.role.capitalized)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 130)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                    .task {
                        if circleService.selectedCircleID != trip.id {
                            circleService.selectCircle(trip.id)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Trip Circle", systemImage: "suitcase.rolling")
                    } description: {
                        Text("Create a temporary Trip Circle to test invitation and membership workflows.")
                    } actions: {
                        NavigationLink("Manage circles") {
                            CircleHubView()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Journey")
        }
    }
}

struct FirebaseActivityHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No activity yet", systemImage: "clock")
            } description: {
                Text("Real activity events will appear after the location, journey and notification services are connected. Demo activity is disabled in signed-in builds.")
            }
            .navigationTitle("Activity")
        }
    }
}
