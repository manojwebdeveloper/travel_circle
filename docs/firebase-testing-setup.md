# Firebase testing setup

This milestone uses Firebase Authentication, Firestore and callable Cloud Functions for testing. The long-term backend can later move behind a dedicated API without changing the SwiftUI feature boundaries.

## 1. Create the Firebase project

1. Create or select a Firebase project.
2. Add an Apple/iOS application with bundle identifier `com.appamore.harbor`.
3. Download `GoogleService-Info.plist`.
4. Place it at `ios/Harbor/Resources/GoogleService-Info.plist`.

The plist is intentionally ignored by Git and must never be committed.

## 2. Enable Sign in with Apple

1. In the Apple Developer portal, enable Sign in with Apple for the App ID matching `com.appamore.harbor`.
2. In Firebase Authentication, enable the Apple provider.
3. Enter the Apple Team ID, Key ID and private key details requested by Firebase.
4. In Xcode, select the correct Apple Development Team and confirm the Sign in with Apple capability is present.

The project already contains `Harbor.entitlements` and the XcodeGen capability configuration.

## 3. Create Firestore

Create the default Cloud Firestore database. Use a European database location suitable for the UK launch where possible.

Do not use test-mode rules. The repository contains explicit rules that deny direct invitation and membership writes.

## 4. Deploy the test API

Install the Firebase CLI, sign in and select the project:

```bash
npm install -g firebase-tools
firebase login
cp .firebaserc.example .firebaserc
firebase use YOUR_FIREBASE_PROJECT_ID
```

Install and compile the functions:

```bash
cd firebase/functions
npm install
npm run build
cd ../..
```

Deploy functions and Firestore configuration:

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

The callable functions deploy to `europe-west2`.

## 5. Generate and run the iOS project

```bash
brew install xcodegen
xcodegen generate
open Harbor.xcodeproj
```

In Xcode:

1. Select the Harbor target.
2. Choose the correct development team.
3. Confirm the bundle identifier matches the Firebase iOS app.
4. Confirm Sign in with Apple is enabled under Signing & Capabilities.
5. Run on a physical iPhone signed in to an Apple Account.

## 6. Test checklist

1. Complete onboarding.
2. Sign in with Apple.
3. Create a Family Circle.
4. Create a Trip Circle with an expiry.
5. Generate an invitation.
6. Open the `harbor://join/123456` style link on another installed test device, scan the QR code, or enter the six-digit code manually.
7. Accept the invitation with another Apple/Firebase account.
8. Confirm both accounts receive the circle in realtime.
9. Revoke an invitation and confirm it can no longer be used.
10. Leave a circle as a member.
11. Delete a circle as its owner.
12. Delete an account and confirm the Apple token is revoked, memberships are removed and the Firebase Authentication user disappears.

## Test-only limitations

- App Check enforcement is disabled in callable functions for the first test milestone.
- Invitation links use the custom `harbor://` scheme. Add an associated domain and HTTPS universal links before public release.
- Push notifications, subscriptions and real background location uploads are intentionally not included in this milestone.
- Six-digit codes are suitable for limited private testing only while App Check and rate limiting are disabled.
- Before production, enable App Attest/App Check, add abuse throttling and move sensitive operations behind the final backend API.
