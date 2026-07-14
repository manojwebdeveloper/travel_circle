import SwiftUI

@main
@MainActor
struct HarborApp: App {
    @StateObject private var appState: AppState
    @StateObject private var authSession: AuthSession
    @StateObject private var circleService: CircleService

    init() {
        let firebaseConfigured = FirebaseBootstrap.configureIfPossible()
        _appState = StateObject(wrappedValue: AppState())
        _authSession = StateObject(wrappedValue: AuthSession(firebaseConfigured: firebaseConfigured))
        _circleService = StateObject(wrappedValue: CircleService(firebaseConfigured: firebaseConfigured))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authSession)
                .environmentObject(circleService)
                .tint(HarborColors.calmTeal)
                .onOpenURL { url in
                    if let code = InvitationLink.code(from: url) {
                        appState.pendingInvitationCode = code
                    }
                }
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

    @Published private(set) var hasCompletedOnboarding: Bool
    @Published var selectedTab: Tab = .map
    @Published var selectedMemberID: UUID?
    @Published var isSharingPaused = false
    @Published var pendingInvitationCode: String?

    init(defaults: UserDefaults = .standard) {
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
}
