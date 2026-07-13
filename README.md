# Travel Circle / Harbor

Native iOS family and temporary journey coordination app.

## Product direction

- Consent-based location sharing only
- Family circles and temporary trip circles
- Map, Journey, Activity and You navigation
- Shared meeting points, ETAs and group arrival coordination
- Explicit location-sharing controls and automatic expiry

## Repository structure

- `ios/Harbor/` — SwiftUI application source
- `docs/` — product, architecture and design decisions
- `project.yml` — XcodeGen project definition

## Local setup

1. Install Xcode 18 or later.
2. Install XcodeGen: `brew install xcodegen`.
3. Run `xcodegen generate` from the repository root.
4. Open `Harbor.xcodeproj`.

The initial implementation uses local mock data. Authentication, location services, MapKit, notifications and the backend API will be introduced behind protocols so the UI remains testable.
