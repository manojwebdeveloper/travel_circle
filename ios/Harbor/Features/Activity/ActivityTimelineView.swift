import SwiftUI

struct ActivityTimelineView: View {
    @ObservedObject var store: PreviewStore
    @State private var selectedFilter = "All"
    private let filters = ["All", "Places", "Check-ins", "Journey", "System"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { filter in
                                Button(filter) { selectedFilter = filter }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selectedFilter == filter ? .white : .secondary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(selectedFilter == filter ? HarborColors.calmTeal : Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Text("TODAY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)

                    VStack(spacing: 0) {
                        ForEach(filteredActivities) { activity in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(color(for: activity.kind))
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activity.title)
                                        .font(.headline)
                                    Text(activity.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(activity.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 14)
                            Divider().padding(.leading, 22)
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Check in", systemImage: "checkmark.circle") { }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var filteredActivities: [HarborActivity] {
        guard selectedFilter != "All" else { return store.activities }
        return store.activities.filter { label(for: $0.kind) == selectedFilter }
    }

    private func label(for kind: HarborActivity.Kind) -> String {
        switch kind {
        case .place: "Places"
        case .checkIn: "Check-ins"
        case .journey: "Journey"
        case .system: "System"
        }
    }

    private func color(for kind: HarborActivity.Kind) -> Color {
        switch kind {
        case .place: HarborColors.safeGreen
        case .checkIn: HarborColors.calmTeal
        case .journey: HarborColors.clearSky
        case .system: HarborColors.warmAmber
        }
    }
}
