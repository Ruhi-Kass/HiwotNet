// Shared Firestore (Admin SDK) bootstrap for the upload scripts.
//
// Safety: by default these scripts only talk to the local emulator. Writing
// to a real project requires BOTH the --allow-remote flag and credentials
// (GOOGLE_APPLICATION_CREDENTIALS), so a stray `node scripts/...` can never
// pollute production data by accident.
import admin from 'firebase-admin';

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const valueOf = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

const usingEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

if (!usingEmulator && !flag('--allow-remote')) {
  console.error(
    'Refusing to write: FIRESTORE_EMULATOR_HOST is not set, so this would target a real project.\n' +
      '  - To record into the emulator, run via `npm run test:record` (or start the emulator first).\n' +
      '  - To write to a real project on purpose: pass --project <id> --allow-remote and set GOOGLE_APPLICATION_CREDENTIALS.',
  );
  process.exit(2);
}

const projectId = valueOf('--project') ?? process.env.GCLOUD_PROJECT ?? 'demo-hiwonet';
admin.initializeApp({ projectId });

export const db = admin.firestore();
export const target = usingEmulator ? `emulator (${process.env.FIRESTORE_EMULATOR_HOST})` : `project ${projectId}`;

// Firestore batches are limited to 500 writes; chunk below that.
export async function writeAll(entries) {
  const CHUNK = 400;
  for (let i = 0; i < entries.length; i += CHUNK) {
    const batch = db.batch();
    for (const { ref, data } of entries.slice(i, i + CHUNK)) batch.set(ref, data);
    await batch.commit();
  }
}
