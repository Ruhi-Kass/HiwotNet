// Stores the test catalog in Firestore as testCases/{id}.
//   node scripts/upload-catalog.js            (emulator only, see _firestore.js)
import { scenarios, toCatalogEntry } from '../test/scenarios.js';
import { planned } from '../test/planned.js';
import { db, target, writeAll } from './_firestore.js';

const catalog = [...scenarios.map(toCatalogEntry), ...planned];
const updatedAt = new Date();

await writeAll(
  catalog.map((c) => ({
    ref: db.collection('testCases').doc(c.id),
    data: { ...c, updatedAt },
  })),
);

console.log(`Uploaded ${catalog.length} test cases to testCases/ on ${target}.`);
