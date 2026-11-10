// Records the latest vitest run in Firestore:
//   testRuns/{runId}                 summary (totals, pass rate, duration)
//   testRuns/{runId}/results/{caseId} one document per executed case
//
// Reads results/vitest.json (written by the vitest json reporter).
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { db, target, writeAll } from './_firestore.js';

const file = fileURLToPath(new URL('../results/vitest.json', import.meta.url));
if (!existsSync(file)) {
  console.error('results/vitest.json not found. Run the tests first (npm test).');
  process.exit(1);
}

const report = JSON.parse(readFileSync(file, 'utf8'));
const runId = new Date(report.startTime ?? Date.now()).toISOString().replace(/[:.]/g, '-');

const results = [];
for (const suite of report.testResults ?? []) {
  for (const t of suite.assertionResults ?? []) {
    const id = /(TC-[A-Z]+(?:-[A-Z]+)*-\d{3})/.exec(t.title ?? '')?.[1];
    if (!id) continue; // skips todo/planned placeholders that have no ID
    results.push({
      id,
      title: t.title,
      status: t.status, // passed | failed | skipped | todo
      durationMs: Math.round(t.duration ?? 0),
      failure: (t.failureMessages ?? []).join('\n').slice(0, 2000) || null,
    });
  }
}

const passed = results.filter((r) => r.status === 'passed').length;
const failed = results.filter((r) => r.status === 'failed').length;
const total = results.length;

await db.collection('testRuns').doc(runId).set({
  startedAt: new Date(report.startTime ?? Date.now()),
  total,
  passed,
  failed,
  passRate: total ? Number((passed / total).toFixed(4)) : 0,
  todo: report.numTodoTests ?? 0,
  suite: 'firestore-and-rtdb-security-rules',
});

await writeAll(
  results.map((r) => ({
    ref: db.collection('testRuns').doc(runId).collection('results').doc(r.id),
    data: r,
  })),
);

console.log(`Recorded run ${runId} on ${target}: ${passed}/${total} passed, ${failed} failed.`);
if (failed > 0) process.exitCode = 1;
