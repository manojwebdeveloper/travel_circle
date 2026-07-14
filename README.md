# Travel Circle / Harbor

Native iOS family and temporary journey coordination app.

## Product direction

- Consent-based location sharing only
- Family circles and temporary trip circles
- Map, Journey, Activity and You navigation
- Shared meeting points, ETAs and group arrival coordination
- Explicit location-sharing controls and automatic expiry

## Current implementation

The current `main` baseline contains:

- Native SwiftUI design system and screens
- Sign in with Apple connected to Firebase Authentication
- Firestore-backed realtime circle summaries
- Callable Cloud Functions for circle creation, invitation creation/lookup/acceptance/revocation, leaving and deleting circles
- QR, custom-link and six-digit invitation flows
- Re-authenticated Apple token revocation and Firebase account deletion
- Locked-down Firestore Security Rules

Push notifications, subscriptions and the real background location upload engine remain later milestones.

## Repository structure

- `ios/Harbor/` — SwiftUI application source
- `firebase/functions/` — trusted callable API
- `firebase/firestore.rules` — client access policy
- `docs/` — product, architecture and setup decisions
- `project.yml` — XcodeGen project definition

## Local setup

1. Follow `docs/firebase-testing-setup.md` to create Firebase and enable Sign in with Apple.
2. Add `GoogleService-Info.plist` to `ios/Harbor/Resources/`.
3. Install XcodeGen: `brew install xcodegen`.
4. Run `xcodegen generate` from the repository root.
5. Open `Harbor.xcodeproj`.
6. Select the correct Apple development team and run on a physical iPhone.

Firebase Apple SDK `12.16.0` is pinned through Swift Package Manager in `project.yml`.
