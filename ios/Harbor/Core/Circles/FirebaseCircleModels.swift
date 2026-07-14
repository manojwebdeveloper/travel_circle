import FirebaseFirestore
import Foundation

struct FirebaseCircleSummary: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case family
        case trip

        var id: String { rawValue }
        var title: String { self == .family ? "Family Circle" : "Trip Circle" }
    }

    let id: String
    let name: String
    let kind: Kind
    let role: String
    let expiresAt: Date?

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let kindValue = data["kind"] as? String,
              let kind = Kind(rawValue: kindValue),
              let role = data["role"] as? String else {
            return nil
        }

        id = document.documentID
        self.name = name
        self.kind = kind
        self.role = role
        expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue()
    }
}

struct InvitationDetails: Hashable {
    let code: String
    let circleID: String
    let circleName: String
    let circleKind: FirebaseCircleSummary.Kind
    let expiresAt: Date
    let invitationURL: URL
}

struct InvitationPreview: Hashable {
    let code: String
    let circleID: String
    let circleName: String
    let circleKind: FirebaseCircleSummary.Kind
    let expiresAt: Date
}

enum InvitationLink {
    static func makeURL(code: String) -> URL {
        URL(string: "harbor://join/\(code)")!
    }

    static func code(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "harbor",
              url.host?.lowercased() == "join" else {
            return nil
        }

        let candidate = url.pathComponents
            .filter { $0 != "/" }
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return normalizedCode(candidate)
    }

    static func normalizedCode(_ value: String?) -> String? {
        guard let value else { return nil }
        let digits = value.filter(\.isNumber)
        return digits.count == 6 ? digits : nil
    }
}
