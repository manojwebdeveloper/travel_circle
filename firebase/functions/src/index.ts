import {randomInt} from "node:crypto";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  DocumentReference,
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const region = "europe-west2";
const invitationLifetimeMs = 24 * 60 * 60 * 1000;
const maximumTripLengthMs = 90 * 24 * 60 * 60 * 1000;

type JsonObject = Record<string, unknown>;
type CircleRole = "owner" | "admin" | "member";

function requireUid(auth: {uid: string} | undefined): string {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in before using this feature.");
  }
  return auth.uid;
}

function objectData(value: unknown): JsonObject {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonObject;
}

function requiredString(data: JsonObject, key: string, maxLength = 120): string {
  const value = data[key];
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${key} is required.`);
  }

  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) {
    throw new HttpsError("invalid-argument", `${key} is invalid.`);
  }
  return trimmed;
}

function optionalNumber(data: JsonObject, key: string): number | undefined {
  const value = data[key];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  return value;
}

function tokenString(token: JsonObject | undefined, key: string): string {
  const value = token?.[key];
  return typeof value === "string" ? value : "";
}

function invitationCode(data: JsonObject): string {
  const raw = requiredString(data, "code", 12).replace(/\D/g, "");
  if (!/^\d{6}$/.test(raw)) {
    throw new HttpsError("invalid-argument", "Enter a valid six-digit invitation code.");
  }
  return raw;
}

function timestampMillis(value: unknown): number | null {
  return value instanceof Timestamp ? value.toMillis() : null;
}

async function circleAndRole(
  circleId: string,
  uid: string,
  acceptedRoles: CircleRole[]
): Promise<{circleRef: DocumentReference; circle: JsonObject; role: CircleRole}> {
  const circleRef = db.collection("circles").doc(circleId);
  const [circleSnapshot, memberSnapshot] = await Promise.all([
    circleRef.get(),
    circleRef.collection("members").doc(uid).get(),
  ]);

  if (!circleSnapshot.exists) {
    throw new HttpsError("not-found", "This circle no longer exists.");
  }
  if (!memberSnapshot.exists) {
    throw new HttpsError("permission-denied", "You are not a member of this circle.");
  }

  const role = memberSnapshot.get("role") as CircleRole;
  if (!acceptedRoles.includes(role)) {
    throw new HttpsError("permission-denied", "You cannot perform this action.");
  }

  return {
    circleRef,
    circle: objectData(circleSnapshot.data()),
    role,
  };
}

async function deleteCircleData(circleId: string): Promise<void> {
  const circleRef = db.collection("circles").doc(circleId);
  const [members, invitations] = await Promise.all([
    circleRef.collection("members").get(),
    db.collection("invitations").where("circleId", "==", circleId).get(),
  ]);

  const deletions: Promise<unknown>[] = [];

  for (const member of members.docs) {
    const userId = member.get("userId") as string | undefined;
    if (userId) {
      deletions.push(
        db.collection("users").doc(userId).collection("circleRefs").doc(circleId).delete()
      );
    }
    deletions.push(member.ref.delete());
  }

  for (const invitation of invitations.docs) {
    deletions.push(invitation.ref.delete());
  }

  await Promise.all(deletions);
  await circleRef.delete();
}

function ensureInvitationUsable(invitation: JsonObject): void {
  if (invitation.revokedAt) {
    throw new HttpsError("failed-precondition", "This invitation has been revoked.");
  }

  const expiresAt = invitation.expiresAt;
  if (!(expiresAt instanceof Timestamp) || expiresAt.toMillis() <= Date.now()) {
    throw new HttpsError("deadline-exceeded", "This invitation has expired.");
  }

  const useCount = typeof invitation.useCount === "number" ? invitation.useCount : 0;
  const maxUses = typeof invitation.maxUses === "number" ? invitation.maxUses : 1;
  if (useCount >= maxUses) {
    throw new HttpsError("resource-exhausted", "This invitation has already been fully used.");
  }
}

export const createCircle = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const data = objectData(request.data);
    const name = requiredString(data, "name", 60);
    const kind = requiredString(data, "kind", 10);

    if (kind !== "family" && kind !== "trip") {
      throw new HttpsError("invalid-argument", "Circle type must be family or trip.");
    }

    let expiresAt: Timestamp | null = null;
    if (kind === "trip") {
      const expiryMs = optionalNumber(data, "expiresAtMs");
      if (!expiryMs || expiryMs <= Date.now() + 60 * 60 * 1000) {
        throw new HttpsError("invalid-argument", "Trip Circles must end at least one hour from now.");
      }
      if (expiryMs > Date.now() + maximumTripLengthMs) {
        throw new HttpsError("invalid-argument", "Trip Circles can last up to 90 days.");
      }
      expiresAt = Timestamp.fromMillis(expiryMs);
    }

    const circleRef = db.collection("circles").doc();
    const userRef = db.collection("users").doc(uid);
    const memberRef = circleRef.collection("members").doc(uid);
    const circleIndexRef = userRef.collection("circleRefs").doc(circleRef.id);
    const displayName = tokenString(request.auth?.token as JsonObject | undefined, "name");
    const email = tokenString(request.auth?.token as JsonObject | undefined, "email");
    const batch = db.batch();

    batch.set(circleRef, {
      name,
      kind,
      ownerId: uid,
      status: "active",
      expiresAt,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      userId: uid,
      displayName,
      role: "owner",
      status: "active",
      sharingEnabled: true,
      joinedAt: FieldValue.serverTimestamp(),
    });
    batch.set(circleIndexRef, {
      circleId: circleRef.id,
      name,
      kind,
      role: "owner",
      expiresAt,
      joinedAt: FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      uid,
      displayName,
      email,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    await batch.commit();
    return {circleId: circleRef.id};
  }
);

export const createInvitation = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const data = objectData(request.data);
    const circleId = requiredString(data, "circleId", 128);
    const {circle} = await circleAndRole(circleId, uid, ["owner", "admin"]);

    const circleName = requiredString(circle, "name", 60);
    const circleKind = requiredString(circle, "kind", 10);
    const circleExpiryMs = timestampMillis(circle.expiresAt);
    const defaultExpiryMs = Date.now() + invitationLifetimeMs;
    const expiresAtMs = circleExpiryMs ? Math.min(circleExpiryMs, defaultExpiryMs) : defaultExpiryMs;

    for (let attempt = 0; attempt < 12; attempt += 1) {
      const code = String(randomInt(100000, 1000000));
      const invitationRef = db.collection("invitations").doc(code);

      try {
        await db.runTransaction(async (transaction) => {
          const existing = await transaction.get(invitationRef);
          if (existing.exists) {
            throw new Error("INVITATION_CODE_COLLISION");
          }

          transaction.create(invitationRef, {
            code,
            circleId,
            circleName,
            circleKind,
            createdBy: uid,
            createdAt: FieldValue.serverTimestamp(),
            expiresAt: Timestamp.fromMillis(expiresAtMs),
            revokedAt: null,
            maxUses: 20,
            useCount: 0,
          });
        });

        return {
          code,
          circleId,
          circleName,
          circleKind,
          expiresAtMs,
        };
      } catch (error) {
        if (error instanceof Error && error.message === "INVITATION_CODE_COLLISION") {
          continue;
        }
        throw error;
      }
    }

    throw new HttpsError("aborted", "A unique invitation code could not be created. Try again.");
  }
);

export const lookupInvitation = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    requireUid(request.auth);
    const code = invitationCode(objectData(request.data));
    const invitationSnapshot = await db.collection("invitations").doc(code).get();

    if (!invitationSnapshot.exists) {
      throw new HttpsError("not-found", "Invitation not found.");
    }

    const invitation = objectData(invitationSnapshot.data());
    ensureInvitationUsable(invitation);

    return {
      code,
      circleId: requiredString(invitation, "circleId", 128),
      circleName: requiredString(invitation, "circleName", 60),
      circleKind: requiredString(invitation, "circleKind", 10),
      expiresAtMs: timestampMillis(invitation.expiresAt),
    };
  }
);

export const acceptInvitation = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const code = invitationCode(objectData(request.data));
    const invitationRef = db.collection("invitations").doc(code);
    const displayName = tokenString(request.auth?.token as JsonObject | undefined, "name");

    const result = await db.runTransaction(async (transaction) => {
      const invitationSnapshot = await transaction.get(invitationRef);
      if (!invitationSnapshot.exists) {
        throw new HttpsError("not-found", "Invitation not found.");
      }

      const invitation = objectData(invitationSnapshot.data());
      ensureInvitationUsable(invitation);

      const circleId = requiredString(invitation, "circleId", 128);
      const circleRef = db.collection("circles").doc(circleId);
      const memberRef = circleRef.collection("members").doc(uid);
      const userCircleRef = db.collection("users").doc(uid).collection("circleRefs").doc(circleId);
      const [circleSnapshot, memberSnapshot] = await Promise.all([
        transaction.get(circleRef),
        transaction.get(memberRef),
      ]);

      if (!circleSnapshot.exists) {
        throw new HttpsError("not-found", "This circle no longer exists.");
      }

      const circle = objectData(circleSnapshot.data());
      const circleExpiresAtMs = timestampMillis(circle.expiresAt);
      if (circleExpiresAtMs && circleExpiresAtMs <= Date.now()) {
        throw new HttpsError("deadline-exceeded", "This Trip Circle has ended.");
      }

      if (!memberSnapshot.exists) {
        transaction.set(memberRef, {
          userId: uid,
          displayName,
          role: "member",
          status: "active",
          sharingEnabled: true,
          joinedAt: FieldValue.serverTimestamp(),
          joinedWithInvitationCode: code,
        });
        transaction.set(userCircleRef, {
          circleId,
          name: requiredString(circle, "name", 60),
          kind: requiredString(circle, "kind", 10),
          role: "member",
          expiresAt: circle.expiresAt ?? null,
          joinedAt: FieldValue.serverTimestamp(),
        });
        transaction.update(invitationRef, {
          useCount: FieldValue.increment(1),
          lastUsedAt: FieldValue.serverTimestamp(),
        });
      }

      return {circleId, alreadyMember: memberSnapshot.exists};
    });

    return result;
  }
);

export const revokeInvitation = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const code = invitationCode(objectData(request.data));
    const invitationRef = db.collection("invitations").doc(code);
    const invitationSnapshot = await invitationRef.get();

    if (!invitationSnapshot.exists) {
      throw new HttpsError("not-found", "Invitation not found.");
    }

    const invitation = objectData(invitationSnapshot.data());
    const circleId = requiredString(invitation, "circleId", 128);
    const createdBy = requiredString(invitation, "createdBy", 128);

    if (createdBy !== uid) {
      await circleAndRole(circleId, uid, ["owner", "admin"]);
    }

    await invitationRef.update({
      revokedAt: FieldValue.serverTimestamp(),
      revokedBy: uid,
    });

    return {revoked: true};
  }
);

export const leaveCircle = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const circleId = requiredString(objectData(request.data), "circleId", 128);
    const {circleRef, role} = await circleAndRole(circleId, uid, ["owner", "admin", "member"]);

    if (role === "owner") {
      throw new HttpsError("failed-precondition", "The owner must delete the circle instead of leaving it.");
    }

    await Promise.all([
      circleRef.collection("members").doc(uid).delete(),
      db.collection("users").doc(uid).collection("circleRefs").doc(circleId).delete(),
    ]);

    return {left: true};
  }
);

export const deleteCircle = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);
    const circleId = requiredString(objectData(request.data), "circleId", 128);
    await circleAndRole(circleId, uid, ["owner"]);
    await deleteCircleData(circleId);
    return {deleted: true};
  }
);

export const deleteAccount = onCall(
  {region, enforceAppCheck: false},
  async (request) => {
    const uid = requireUid(request.auth);

    const ownedCircles = await db.collection("circles").where("ownerId", "==", uid).get();
    for (const circle of ownedCircles.docs) {
      await deleteCircleData(circle.id);
    }

    const remainingMemberships = await db
      .collectionGroup("members")
      .where("userId", "==", uid)
      .get();

    for (const membership of remainingMemberships.docs) {
      const circleRef = membership.ref.parent.parent;
      if (circleRef) {
        await Promise.all([
          membership.ref.delete(),
          db.collection("users").doc(uid).collection("circleRefs").doc(circleRef.id).delete(),
        ]);
      }
    }

    const [createdInvitations, circleRefs] = await Promise.all([
      db.collection("invitations").where("createdBy", "==", uid).get(),
      db.collection("users").doc(uid).collection("circleRefs").get(),
    ]);

    await Promise.all([
      ...createdInvitations.docs.map((document) => document.ref.delete()),
      ...circleRefs.docs.map((document) => document.ref.delete()),
    ]);

    await db.collection("users").doc(uid).delete();
    await getAuth().deleteUser(uid);

    return {deleted: true};
  }
);
