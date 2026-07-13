import MapKit
import SwiftUI

struct HarborMapView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var store: PreviewStore

    private let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1270),
        span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(initialPosition: .region(region)) {
                ForEach(store.members) { member in
                    Annotation(member.name, coordinate: member.coordinate) {
                        Button {
                            withAnimation(.snappy) {
                                appState.selectedMemberID = member.id
                            }
                        } label: {
                            HarborAvatar(
                                member: member,
                                size: 52,
                                selected: appState.selectedMemberID == member.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topChrome

                if appState.isSharingPaused {
                    pausedBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                memberCarousel
                    .padding(.bottom, 98)
            }
            .padding(.top, 8)
        }
        .sheet(item: selectedMemberBinding) { member in
            MemberDetailSheet(member: member)
                .presentationDetents([.height(430), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(430)))
        }
    }

    private var selectedMemberBinding: Binding<HarborMember?> {
        Binding(
            get: { store.members.first(where: { $0.id == appState.selectedMemberID }) },
            set: { appState.selectedMemberID = $0?.id }
        )
    }

    private var topChrome: some View {
        HStack {
            Button { appState.selectedTab = .you } label: {
                Circle()
                    .fill(HarborColors.warmAmber.opacity(0.22))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text("A")
                            .font(.headline)
                            .foregroundStyle(HarborColors.warmAmber)
                    }
            }

            Spacer()

            Menu {
                ForEach(store.circles) { circle in
                    Button(circle.name) { }
                }
            } label: {
                Label("The Harris Family", systemImage: "chevron.down")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .overlay { Capsule().stroke(HarborColors.mineralBorder.opacity(0.7), lineWidth: 0.5) }
            }

            Spacer()

            Button { } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
    }

    private var pausedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.fill")
                .foregroundStyle(HarborColors.slate)
                .frame(width: 34, height: 34)
                .background(HarborColors.slate.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Your location sharing is paused")
                    .font(.subheadline.weight(.semibold))
                Text("Your circle sees your last shared location.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Resume") {
                withAnimation(.snappy) { appState.isSharingPaused = false }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HarborColors.mineralBorder.opacity(0.7), lineWidth: 0.5)
        }
        .padding(.horizontal, 16)
    }

    private var memberCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    appState.selectedMemberID = nil
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(appState.selectedMemberID == nil ? .white : .primary)
                        .padding(.horizontal, 18)
                        .frame(height: 46)
                        .background(appState.selectedMemberID == nil ? HarborColors.calmTeal : Color.clear)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                }

                ForEach(store.members) { member in
                    Button {
                        appState.selectedMemberID = member.id
                    } label: {
                        HStack(spacing: 8) {
                            HarborAvatar(member: member, size: 30)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(member.name)
                                    .font(.caption.weight(.semibold))
                                Text(member.presence.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 7)
                        .padding(.trailing, 14)
                        .frame(height: 46)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(
                                appState.selectedMemberID == member.id ? member.tint : HarborColors.mineralBorder.opacity(0.7),
                                lineWidth: appState.selectedMemberID == member.id ? 2 : 0.5
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

private struct MemberDetailSheet: View {
    let member: HarborMember

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    HarborAvatar(member: member, size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name)
                            .font(.title2.bold())
                        Text(member.presence.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(member.batteryLevel)%")
                        .font(.subheadline.weight(.semibold))
                }

                HStack(spacing: 10) {
                    quickAction("Check in", symbol: "checkmark.circle")
                    quickAction("Directions", symbol: "arrow.triangle.turn.up.right.diamond")
                    quickAction("Notify", symbol: "bell")
                }

                VStack(spacing: 0) {
                    detailRow("Location", value: member.locationName)
                    detailRow("Status", value: member.presence.rawValue)
                    detailRow("Battery", value: "\(member.batteryLevel)%")
                    detailRow("Sharing", value: "Shared securely")
                }
                .harborCard()

                Text("Harbor labels delayed or offline positions as last known locations. It never presents stale data as live.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }

    private func quickAction(_ title: String, symbol: String) -> some View {
        Button { } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HarborColors.calmTeal)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(HarborColors.morningMist.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
    }
}
