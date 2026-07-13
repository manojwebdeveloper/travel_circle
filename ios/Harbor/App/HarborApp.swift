import SwiftUI

@main
struct HarborApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(HarborColors.calmTeal)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case map = "Map"
        case journey = "Journey"
        case activity = "Activity"
        case you = "You"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .map: "map.fill"
            case .journey: "point.topleft.down.to.point.bottomright.curvepath.fill"
            case .activity: "clock.fill"
            case .you: "person.crop.circle.fill"
            }
        }
    }

    @Published var hasCompletedOnboarding = false
    @Published var selectedTab: Tab = .map
    @Published var selectedMemberID: UUID?
    @Published var isSharingPaused = false
}
