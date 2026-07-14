import FirebaseCore
import Foundation

enum FirebaseBootstrap {
    /// Configures Firebase only when a real GoogleService-Info.plist is bundled.
    /// This keeps local design previews usable before the Firebase project is connected.
    @discardableResult
    static func configureIfPossible() -> Bool {
        if FirebaseApp.app() != nil {
            return true
        }

        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            return false
        }

        FirebaseApp.configure(options: options)
        return true
    }
}
