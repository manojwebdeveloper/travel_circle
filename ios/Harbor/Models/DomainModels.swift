import CoreLocation
import Foundation
import SwiftUI

struct HarborMember: Identifiable, Hashable {
    enum Presence: String {
        case live = "Live now"
        case recent = "Updated recently"
        case arrived = "Arrived"
        case travelling = "On the way"
        case delayed = "Location delayed"
        case offline = "Phone offline"
        case paused = "Sharing paused"
    }

    let id: UUID
    var name: String
    var initials: String
    var coordinate: CLLocationCoordinate2D
    var locationName: String
    var batteryLevel: Int
    var presence: Presence
    var tint: Color
    var etaText: String?

    static func == (lhs: HarborMember, rhs: HarborMember) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HarborCircle: Identifiable, Hashable {
    enum Kind: String {
        case family = "Family Circle"
        case trip = "Trip Circle"
    }

    let id: UUID
    var name: String
    var kind: Kind
    var memberIDs: [UUID]
    var expiresAt: Date?
}

struct HarborJourney: Identifiable, Hashable {
    let id: UUID
    var title: String
    var destinationName: String
    var destinationAddress: String
    var meetupDate: Date
    var destinationCoordinate: CLLocationCoordinate2D
    var memberIDs: [UUID]

    static func == (lhs: HarborJourney, rhs: HarborJourney) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HarborActivity: Identifiable, Hashable {
    enum Kind {
        case place
        case checkIn
        case journey
        case system
    }

    let id: UUID
    var date: Date
    var title: String
    var detail: String
    var kind: Kind
}
