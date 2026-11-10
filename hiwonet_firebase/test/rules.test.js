import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { scenarios } from './scenarios.js';
import { contextFor, createEnv, execute, seed } from './helpers.js';

let env;

beforeAll(async () => {
  env = await createEnv();
});

afterAll(async () => {
  await env?.cleanup();
});

// Every scenario starts from the same seeded baseline so that an allowed
// write in one test can never change the outcome of another.
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearDatabase();
  await seed(env);
});

const areas = [...new Set(scenarios.map((s) => s.area))];

for (const area of areas) {
  describe(area, () => {
    for (const s of scenarios.filter((x) => x.area === area)) {
      // The ID prefix is what scripts/upload-results.js uses to match each
      // result back to its catalog entry.
      it(`${s.id} ${s.title}`, async () => {
        const ctx = contextFor(env, s.actor);
        const outcome = execute(s, ctx);
        if (s.expect === 'allow') {
          await assertSucceeds(outcome);
        } else {
          await assertFails(outcome);
        }
      });
    }
  });
}

// Scenarios that need infrastructure which does not exist yet. They show up
// as "todo" in the report rather than being silently forgotten.
describe('Planned (not yet implementable at the rules layer)', () => {
  it.todo('Admin without a second factor is denied access to admin data (Phase 6: Identity Platform MFA)');
  it.todo('A revoked refresh token stops working once the ID token expires (needs Auth emulator + functions)');
});
