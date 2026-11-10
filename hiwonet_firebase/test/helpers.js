import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { ACTORS } from './scenarios.js';

// A demo- project id guarantees the Firebase tooling never touches a real
// project, even if credentials happen to be present on the machine.
export const PROJECT_ID = 'demo-hiwonet';

const read = (rel) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), 'utf8');

export async function createEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: read('../firestore.rules') },
    database: { rules: read('../database.rules.json') },
  });
}

export function contextFor(env, actorKey) {
  const actor = ACTORS[actorKey];
  return actor.uid
    ? env.authenticatedContext(actor.uid, actor.claims)
    : env.unauthenticatedContext();
}

// Baseline data every scenario starts from (rules bypassed while seeding).
export async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const now = Date.now();

    await db.doc('users/u-disp').set({ name: 'Meron A.', role: 'dispatcher', status: 'active' });
    await db.doc('users/u-admin').set({ name: 'Admin One', role: 'admin', status: 'active' });
    await db.doc('users/u-caller').set({ name: 'Sara Getachew', role: 'caller', status: 'active' });

    await db.doc('registrationRequests/r1').set({ name: 'Dawit Alemu', email: 'dawit@example.et', status: 'pending' });

    await db.doc('hospitals/h1').set({ name: "St. Luke's Hospital", beds: 50, icuBeds: 12, active: true });

    await db.doc('ambulances/AMB-4712').set({ homeBaseId: 'h1', crewUid: 'u-crewA', status: 'available' });
    await db.doc('ambulances/AMB-4713').set({ homeBaseId: 'h1', crewUid: 'u-crewB', status: 'available' });

    await db.doc('incidents/inc1').set({ severity: 'P1', status: 'new', createdAt: now });
    await db.doc('incidents/inc1/events/e1').set({ type: 'created', at: now });

    await db.doc('alerts/al1').set({ kind: 'incident', message: 'New P1 incident' });
    await db.doc('auditLog/a1').set({ actor: 'Meron A. (Admin)', action: 'registration', ts: now });
    await db.doc('stats/network').set({ users: 312, hospitals: 14, ambulances: 48 });

    await db.doc('testRuns/run1').set({ total: 1 });
    await db.doc('testCases/tc1').set({ title: 'seed' });

    const rtdb = ctx.database();
    await rtdb.ref('positions/AMB-4712').set({ lat: 9.03, lng: 38.74, ts: now });
    await rtdb.ref('positions/AMB-4713').set({ lat: 9.01, lng: 38.76, ts: now });
  });
}

// Executes one scenario's operation as the given context.
export function execute(scenario, ctx) {
  const payload = typeof scenario.data === 'function' ? scenario.data() : scenario.data;

  if (scenario.store === 'firestore') {
    const db = ctx.firestore();
    switch (scenario.op) {
      case 'get':
        return db.doc(scenario.target).get();
      case 'list': {
        const base = db.collection(scenario.target);
        return (scenario.query ? scenario.query(base) : base).get();
      }
      case 'create':
        return db.doc(scenario.target).set(payload ?? { x: 1 });
      case 'update':
        return db.doc(scenario.target).update(payload);
      case 'delete':
        return db.doc(scenario.target).delete();
      default:
        throw new Error(`Unknown firestore op: ${scenario.op}`);
    }
  }

  const ref = ctx.database().ref(scenario.target);
  switch (scenario.op) {
    case 'get':
      return ref.get();
    case 'set':
      return ref.set(payload);
    case 'remove':
      return ref.remove();
    default:
      throw new Error(`Unknown rtdb op: ${scenario.op}`);
  }
}
