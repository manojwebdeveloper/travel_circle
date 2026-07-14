import CoreLocation
import Foundation

@MainActor
final class PreviewStore: ObservableObject {
    @Published var members: [HarborMember]
    @Published var circles: [HarborCircle]
    @Published var activeJourney: HarborJourney
    @Published var activities: [HarborActivity]

    init() {
        let maya = HarborMember(
            id: UUID(),
            name: "Maya",
            initials: "M",
            coordinate: CLLocationCoordinate2D(latitude: 51.5079, longitude: -0.1285),
            locationName: "Hotel Le Marais",
            batteryLevel: 82,
            presence: .arrived,
            tint: HarborColors.clearSky,
            etaText: "Arrived 18:02"
        )
        let james = HarborMember(
            id: UUID(),
            name: "James",
            initials: "J",
            coordinate: CLLocationCoordinate2D(latitude: 51.5118, longitude: -0.1185),
            locationName: "On the way",
            batteryLevel: 54,
            presence: .travelling,
            tint: HarborColors.calmTeal,
            etaText: "8 min away"
        )
        let emily = HarborMember(
            id: UUID(),
            name: "Emily",
            initials: "E",
            coordinate: CLLocationCoordinate2D(latitude: 51.5155, longitude: -0.1420),
            locationName: "Last known near Oxford Circus",
            batteryLevel: 19,
            presence: .delayed,
            tint: HarborColors.softCoral,
            etaText: "Last seen 12 min ago"
        )
        let alex = HarborMember(
            id: UUID(),
            name: "Alex",
            initials: "A",
            coordinate: CLLocationCoordinate2D(latitude: 51.5033, longitude: -0.1195),
            locationName: "Waterloo Station",
            batteryLevel: 71,
            presence: .travelling,
            tint: HarborColors.warmAmber,
            etaText: "18 min away"
        )

        let initialMembers = [maya, james, emily, alex]
        let memberIDs = initialMembers.map(\.id)

        members = initialMembers
        circles = [
            HarborCircle(
                id: UUID(),
                name: "The Harris Family",
                kind: .family,
                memberIDs: memberIDs,
                expiresAt: nil
            ),
            HarborCircle(
                id: UUID(),
                name: "Paris Weekend",
                kind: .trip,
                memberIDs: memberIDs,
                expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: .now)
            )
        ]
        activeJourney = HarborJourney(
            id: UUID(),
            title: "Paris Weekend",
            destinationName: "Hotel Le Marais",
            destinationAddress: "12 Rue du Temple, Paris",
            meetupDate: Calendar.current.date(byAdding: .minute, value: 45, to: .now) ?? .now,
            destinationCoordinate: CLLocationCoordinate2D(latitude: 51.5079, longitude: -0.1285),
            memberIDs: memberIDs
        )
        activities = [
            HarborActivity(id: UUID(), date: .now, title: "Maya arrived at the meeting point", detail: "Hotel Le Marais", kind: .journey),
            HarborActivity(id: UUID(), date: .now.addingTimeInterval(-900), title: "James checked in", detail: "On my way", kind: .checkIn),
            HarborActivity(id: UUID(), date: .now.addingTimeInterval(-1_800), title: "Emily’s location is delayed", detail: "Last updated 12 minutes ago", kind: .system)
        ]
    }
}
