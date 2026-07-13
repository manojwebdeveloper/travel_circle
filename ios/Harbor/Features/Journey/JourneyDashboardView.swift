import SwiftUI

struct JourneyDashboardView: View {
    @ObservedObject var store: PreviewStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    destinationCard
                    summaryStrip
                    arrivalBoard
                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Journey")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit meeting point", systemImage: "mappin.and.ellipse") { }
                        Button("Invite people", systemImage: "person.badge.plus") { }
                        Button("End journey", systemImage: "stop.circle") { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var destinationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.activeJourney.title)
                        .font(.title2.bold())
                    Text("Temporary trip circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HarborStatusPill(text: "Ends automatically", color: HarborColors.calmTeal)
            }

            Divider()

            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.activeJourney.destinationName)
                        .font(.headline)
                    Text(store.activeJourney.destinationAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HarborColors.calmTeal)
            }

            HStack {
                Label(store.activeJourney.meetupDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                Spacer()
                Button("Directions") { }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HarborColors.calmTeal)
            }
            .font(.subheadline)
        }
        .harborCard()
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryMetric(value: arrivedCount, title: "Arrived", color: HarborColors.safeGreen)
            summaryMetric(value: travellingCount, title: "On the way", color: HarborColors.clearSky)
            summaryMetric(value: delayedCount, title: "Delayed", color: HarborColors.warmAmber)
        }
    }

    private var arrivalBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Arrival board")
                    .font(.title3.bold())
                Spacer()
                Text("Live group status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(store.members.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 12) {
                        HarborAvatar(member: member, size: 42)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(member.name)
                                .font(.headline)
                            Text(member.locationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(member.presence.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(statusColor(for: member))
                            if let etaText = member.etaText {
                                Text(etaText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 13)

                    if index < store.members.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
        }
    }

    private var privacyNote: some View {
        Label {
            Text("Journey sharing stops at the selected expiry. Members can pause or leave at any time.")
        } icon: {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(HarborColors.calmTeal)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(16)
        .background(HarborColors.seaGlass.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryMetric(value: Int, title: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var arrivedCount: Int {
        store.members.filter { $0.presence == .arrived }.count
    }

    private var travellingCount: Int {
        store.members.filter { $0.presence == .travelling }.count
    }

    private var delayedCount: Int {
        store.members.filter { [.delayed, .offline].contains($0.presence) }.count
    }

    private func statusColor(for member: HarborMember) -> Color {
        switch member.presence {
        case .arrived, .live, .recent: HarborColors.safeGreen
        case .travelling: HarborColors.clearSky
        case .delayed: HarborColors.warmAmber
        case .offline, .paused: HarborColors.slate
        }
    }
}
