@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseFunctions
import Foundation

// Firebase Functions accepts immutable Foundation dictionaries, but its Objective-C
// API does not declare Sendable conformance. Harbor only places immutable String and
// NSNumber values in these request dictionaries.
extension NSDictionary: @retroactive @unchecked Sendable {}

@MainActor
final class CircleService: ObservableObject {
    @Published private(set) var circles: [FirebaseCircleSummary] = []
    @Published private(set) var members: [FirebaseCircleMember] = []
    @Published private(set) var selectedCircleID: String?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let isFirebaseConfigured: Bool

    private let region = "europe-west2"
    private var circleListener: ListenerRegistration?
    private var memberListener: ListenerRegistration?
    private var observedUserID: String?

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
    }

    var selectedCircle: FirebaseCircleSummary? {
        guard let selectedCircleID else { return nil }
        return circles.first { $0.id == selectedCircleID }
    }

    func observeCircles(for userID: String?) {
        guard observedUserID != userID else { return }

        circleListener?.remove()
        circleListener = nil
        memberListener?.remove()
        memberListener = nil
        observedUserID = userID
        circles = []
        members = []
        selectedCircleID = nil

        guard isFirebaseConfigured, let userID else { return }

        isLoading = true
        circleListener = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("circleRefs")
            .order(by: "joinedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let decodedCircles = snapshot?.documents.compactMap {
                        FirebaseCircleSummary(document: $0)
                    } ?? []
                    self.circles = decodedCircles

                    let nextSelection: String?
                    if let selectedCircleID = self.selectedCircleID,
                       decodedCircles.contains(where: { $0.id == selectedCircleID }) {
                        nextSelection = selectedCircleID
                    } else {
                        nextSelection = decodedCircles.first?.id
                    }
                    self.selectCircle(nextSelection)
                }
            }
    }

    func selectCircle(_ circleID: String?) {
        guard selectedCircleID != circleID else { return }

        memberListener?.remove()
        memberListener = nil
        selectedCircleID = circleID
        members = []

        guard isFirebaseConfigured, let circleID else { return }

        memberListener = Firestore.firestore()
            .collection("circles")
            .document(circleID)
            .collection("members")
            .order(by: "joinedAt")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.members = snapshot?.documents.compactMap {
                        FirebaseCircleMember(document: $0)
                    } ?? []
                }
            }
    }

    @discardableResult
    func createCircle(
        name: String,
        kind: FirebaseCircleSummary.Kind,
        expiresAt: Date?
    ) async throws -> String {
        var values: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "kind": kind.rawValue
        ]
        if let expiresAt {
            values["expiresAtMs"] = NSNumber(value: Int64(expiresAt.timeIntervalSince1970 * 1_000))
        }

        let data = try await call(
            "createCircle",
            payload: NSDictionary(dictionary: values)
        )
        guard let circleID = data["circleId"] as? String else {
            throw CircleServiceError.invalidServerResponse
        }
        selectCircle(circleID)
        return circleID
    }

    func createInvitation(circleID: String) async throws -> InvitationDetails {
        let data = try await call(
            "createInvitation",
            payload: NSDictionary(object: circleID, forKey: "circleId" as NSString)
        )
        guard let code = data["code"] as? String,
              let circleName = data["circleName"] as? String,
              let kindValue = data["circleKind"] as? String,
              let kind = FirebaseCircleSummary.Kind(rawValue: kindValue),
              let expiresAt = Self.date(fromMilliseconds: data["expiresAtMs"]) else {
            throw CircleServiceError.invalidServerResponse
        }

        return InvitationDetails(
            code: code,
            circleID: circleID,
            circleName: circleName,
            circleKind: kind,
            expiresAt: expiresAt,
            invitationURL: InvitationLink.makeURL(code: code)
        )
    }

    func lookupInvitation(code: String) async throws -> InvitationPreview {
        guard let normalizedCode = InvitationLink.normalizedCode(code) else {
            throw CircleServiceError.invalidInvitationCode
        }

        let data = try await call(
            "lookupInvitation",
            payload: NSDictionary(object: normalizedCode, forKey: "code" as NSString)
        )
        guard let circleID = data["circleId"] as? String,
              let circleName = data["circleName"] as? String,
              let kindValue = data["circleKind"] as? String,
              let kind = FirebaseCircleSummary.Kind(rawValue: kindValue),
              let expiresAt = Self.date(fromMilliseconds: data["expiresAtMs"]) else {
            throw CircleServiceError.invalidServerResponse
        }

        return InvitationPreview(
            code: normalizedCode,
            circleID: circleID,
            circleName: circleName,
            circleKind: kind,
            expiresAt: expiresAt
        )
    }

    func acceptInvitation(code: String) async throws {
        guard let normalizedCode = InvitationLink.normalizedCode(code) else {
            throw CircleServiceError.invalidInvitationCode
        }
        let data = try await call(
            "acceptInvitation",
            payload: NSDictionary(object: normalizedCode, forKey: "code" as NSString)
        )
        if let circleID = data["circleId"] as? String {
            selectCircle(circleID)
        }
    }

    func revokeInvitation(code: String) async throws {
        guard let normalizedCode = InvitationLink.normalizedCode(code) else {
            throw CircleServiceError.invalidInvitationCode
        }
        _ = try await call(
            "revokeInvitation",
            payload: NSDictionary(object: normalizedCode, forKey: "code" as NSString)
        )
    }

    func leaveCircle(circleID: String) async throws {
        _ = try await call(
            "leaveCircle",
            payload: NSDictionary(object: circleID, forKey: "circleId" as NSString)
        )
    }

    func deleteCircle(circleID: String) async throws {
        _ = try await call(
            "deleteCircle",
            payload: NSDictionary(object: circleID, forKey: "circleId" as NSString)
        )
    }

    private func call(
        _ name: String,
        payload: NSDictionary
    ) async throws -> [String: Any] {
        guard isFirebaseConfigured else {
            throw CircleServiceError.firebaseNotConfigured
        }

        errorMessage = nil

        do {
            let response = try await Self.performCallable(
                region: region,
                name: name,
                payload: payload
            )
            return response.data
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    nonisolated private static func performCallable(
        region: String,
        name: String,
        payload: NSDictionary
    ) async throws -> FirebaseCallableResponse {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<FirebaseCallableResponse, Error>) in
            let callable = Functions.functions(region: region).httpsCallable(name)
            callable.call(payload) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = result?.data as? [String: Any] else {
                    continuation.resume(throwing: CircleServiceError.invalidServerResponse)
                    return
                }
                continuation.resume(returning: FirebaseCallableResponse(data: data))
            }
        }
    }

    private static func date(fromMilliseconds value: Any?) -> Date? {
        if let number = value as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue / 1_000)
        }
        if let integer = value as? Int64 {
            return Date(timeIntervalSince1970: Double(integer) / 1_000)
        }
        return nil
    }
}

private struct FirebaseCallableResponse: @unchecked Sendable {
    let data: [String: Any]
}

enum CircleServiceError: LocalizedError {
    case firebaseNotConfigured
    case invalidInvitationCode
    case invalidServerResponse

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            "Firebase has not been configured for this build."
        case .invalidInvitationCode:
            "Enter a valid six-digit invitation code."
        case .invalidServerResponse:
            "Harbor received an invalid response. Please try again."
        }
    }
}
