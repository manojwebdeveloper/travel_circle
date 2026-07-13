# Harbor architecture direction

## Current milestone

The current branch is a native SwiftUI foundation using deterministic preview data. It intentionally separates product UI from future network and location services.

## Product boundaries

- Location sharing is explicit, revocable and circle-scoped.
- Temporary trip circles have an expiry.
- Stale positions are represented as delayed or last known, never as live.
- The primary differentiator is group journey coordination, not generic phone tracking.

## Planned service boundaries

### Identity

Sign in with Apple issues an identity credential. The backend validates the credential and returns a short-lived Harbor API token.

### Circle service

Owns family and trip circles, membership, invitations, roles, consent records and expiry.

### Location service

A native Core Location engine batches updates to an authenticated API. The API validates membership, device registration, timestamp, sequence and sharing state before accepting an update.

### Journey service

Owns meeting points, member journey sessions, ETA snapshots, arrival states and automatic expiry.

### Notification service

Delivers APNs events containing an event identifier only. Precise coordinates are never placed in a notification payload.

## Proposed backend

- Cloud Run REST API
- Firebase Authentication
- Firestore for circles, permissions and current state
- Pub/Sub for asynchronous location processing
- Cloud Storage for compressed route history
- APNs/FCM for notifications
- App Attest for production request verification

## Security constraints

- No advertising SDKs
- No coordinates in analytics
- No unsupported end-to-end encryption claims
- Server-side circle authorisation on every protected request
- Automatic deletion of expired temporary data
- Immediate sharing revocation when a member leaves or pauses
