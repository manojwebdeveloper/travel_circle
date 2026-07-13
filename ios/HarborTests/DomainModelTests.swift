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
}
