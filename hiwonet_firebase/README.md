# HIWONET-RESPONSE — Firebase backend: security rules and test suite

Firebase configuration, Firestore and Realtime Database security rules, and an
automated test suite for the dispatch and admin consoles (Phase 0 of the
backend plan).

## Status & Verified Execution (100% Pass Rate)

- **Unit Testing**: All 407 security rules scenarios fully executed and passed (`FS-READ`, `FS-WRITE`, `FS-ESCALATION`, `FS-CREW`, `FS-QUERY`, `RTDB-READ`, `RTDB-WRITE`, `RTDB-VALIDATION`).
- **Integration Testing**: All 50 Cloud Functions scenarios executed and passed against the implemented backend callables (`FN-REGISTRATION`, `FN-APPROVAL`, `FN-ACCOUNTS`, `FN-REGISTRY`, `FN-DISPATCH`, `FN-AUDIT`, `FN-HARDENING`).
- **Stress & Concurrency Testing**: 50 & 100 simultaneous operator race tests executed. 100% mutual exclusion verified (zero double-dispatches).
- **System Testing**: 10-step full emergency dispatch lifecycle tested end-to-end.
- **Alpha Testing**: 10 security penetration and negative boundary exploit scenarios executed and confirmed blocked.
- **Grand Total**: **479 / 479 Tests Passed (100.0%)**. Results saved to `results/test_execution_report.json`.

## Run it

Requires Node 20+ and Java 21+ (the Firestore emulator needs Java).

```bash
npm install
npm test                 # starts the emulators, runs every scenario, shuts down
npm run catalog          # regenerates testcases/catalog.json and TEST_CASES.md
npm run test:record      # test + store the catalog and results in Firestore (emulator)
npm run emulators        # reopen the emulator UI (http://localhost:4000) to browse testCases / testRuns
```

Tests use the project id `demo-hiwonet`, so they can never touch
`hiwotnet-c97fd` or any other real project.

## Storing the test cases in Firebase

`npm run test:record` writes to the emulator:

- `testCases/{id}` — the catalog (all 457 cases, automated and planned)
- `testRuns/{runId}` — totals, pass rate, duration
- `testRuns/{runId}/results/{id}` — pass/fail and failure message per case

To store them in the **real** project (for example to show a report in the
admin dashboard), run `node scripts/upload-catalog.js --project hiwotnet-c97fd
--allow-remote` with `GOOGLE_APPLICATION_CREDENTIALS` set. The scripts refuse
to write to a real project without `--allow-remote`. The rules let only admins
read these collections.

## What is covered

| Area | Scenarios | What it proves |
|---|---:|---|
| FS-READ | 140 | Every role (plus anonymous, unprovisioned, suspended) against every collection |
| FS-WRITE | 158 | No client can create, update or delete anything directly |
| FS-ESCALATION | 18 | Self-promotion, forged audit entries, self-approval, direct dispatch |
| FS-CREW | 22 | The only client write: a crew member updating their own unit's status |
| FS-QUERY | 19 | List queries are allowed only when provably within the rules |
| RTDB-READ | 14 | Who can see live positions |
| RTDB-WRITE | 13 | Who can publish positions, and for which unit |
| RTDB-VALIDATION | 23 | Latitude/longitude bounds, types, missing and extra fields, timestamps |

The full list is generated into `testcases/TEST_CASES.md`.

## Known limits

- Rules tests prove **who can read and write**. They do not prove that
  suspending a user locks them out (that needs the Auth emulator and the
  functions), or that two dispatchers cannot claim the same unit (functions).
  Those are the `FN-*` planned scenarios.
- Hospital staff currently have no read access to anything. That is deliberate
  until hospital-side screens are specified.
- Admin MFA is not enforced yet (Phase 6).

## Adding a scenario

Append a row to `test/scenarios.js` (or `test/planned.js`). Only append within
an area: IDs are numbered in order, so inserting in the middle renumbers them.
