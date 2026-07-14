import XCTest
@testable import Harbor

final class DomainModelTests: XCTestCase {
    @MainActor
    func testPreviewStoreContainsTemporaryTripCircle() {
        let store = PreviewStore()

        let trip = store.circles.first { $0.kind == .trip }

        XCTAssertNotNil(trip)
        XCTAssertNotNil(trip?.expiresAt)
        XCTAssertEqual(store.activeJourney.memberIDs.count, store.members.count)
    }

    @MainActor
    func testDelayedMemberIsNotRepresentedAsLive() {
        let store = PreviewStore()
        let delayedMember = store.members.first { $0.presence == .delayed }

        XCTAssertNotNil(delayedMember)
        XCTAssertNotEqual(delayedMember?.presence, .live)
        XCTAssertTrue(delayedMember?.locationName.localizedCaseInsensitiveContains("last known") == true)
    }

    func testInvitationLinkParsesSixDigitCode() throws {
        let url = try XCTUnwrap(URL(string: "harbor://join/482915"))

        XCTAssertEqual(InvitationLink.code(from: url), "482915")
    }

    func testInvitationLinkRejectsWrongSchemeAndInvalidCode() {
        XCTAssertNil(InvitationLink.code(from: URL(string: "https://example.com/join/482915")!))
        XCTAssertNil(InvitationLink.normalizedCode("12345"))
        XCTAssertEqual(InvitationLink.normalizedCode("482 915"), "482915")
    }

    @MainActor
    func testOnboardingCompletionPersists() throws {
        let suiteName = "DomainModelTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = AppState(defaults: defaults)
        XCTAssertFalse(state.hasCompletedOnboarding)

        state.completeOnboarding(defaults: defaults)

        XCTAssertTrue(state.hasCompletedOnboarding)
        XCTAssertTrue(AppState(defaults: defaults).hasCompletedOnboarding)
    }
}
