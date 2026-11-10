// Scenarios for the Cloud Functions layer (Phases 1-5 of the backend plan).
//
// These are DOCUMENTED but NOT automated: the functions do not exist yet, so
// there is nothing to execute. They are stored in the catalog with
// status "planned" so they can be tracked, reviewed and turned into
// automated tests as each phase is built (Functions + Auth emulators).

const planned = [];
const counters = {};

function add(area, title, expected) {
  counters[area] = (counters[area] || 0) + 1;
  planned.push({
    id: `TC-${area}-${String(counters[area]).padStart(3, '0')}`,
    area,
    status: 'planned',
    store: 'functions',
    title,
    expected,
  });
}

// Phase 1 - provisioning
add('FN-REGISTRATION', 'submitRegistration with all valid fields creates a pending request and no Auth account', 'success');
add('FN-REGISTRATION', 'submitRegistration with a missing required field is rejected', 'invalid-argument');
add('FN-REGISTRATION', 'submitRegistration with a malformed email is rejected', 'invalid-argument');
add('FN-REGISTRATION', 'submitRegistration that includes a password field never stores it', 'success, password ignored');
add('FN-REGISTRATION', 'submitRegistration for an email that already has an account is rejected', 'already-exists');
add('FN-REGISTRATION', 'submitRegistration for an email with a pending request is rejected', 'already-exists');
add('FN-REGISTRATION', 'More than N submissions from one client in a minute are rate-limited', 'resource-exhausted');
add('FN-REGISTRATION', 'submitRegistration without a valid App Check token is rejected', 'unauthenticated');

add('FN-APPROVAL', 'approveRegistration by an admin creates the Auth user, sets the role claim, creates the user doc and writes an audit entry', 'success');
add('FN-APPROVAL', 'approveRegistration sends a set-password email instead of a password', 'success');
add('FN-APPROVAL', 'approveRegistration by a dispatcher is rejected', 'permission-denied');
add('FN-APPROVAL', 'approveRegistration by an unauthenticated caller is rejected', 'unauthenticated');
add('FN-APPROVAL', 'approveRegistration twice on the same request is idempotent', 'success, one account');
add('FN-APPROVAL', 'approveRegistration on a rejected request is refused', 'failed-precondition');
add('FN-APPROVAL', 'rejectRegistration records the reason and writes an audit entry', 'success');
add('FN-APPROVAL', 'approveRegistration for a non-existent request id is rejected', 'not-found');

add('FN-ACCOUNTS', 'setUserStatus suspended disables the Auth user, revokes tokens and writes an audit entry', 'success');
add('FN-ACCOUNTS', 'A suspended user cannot sign in again', 'auth/user-disabled');
add('FN-ACCOUNTS', 'setUserStatus active (reinstate) re-enables the Auth user and writes an audit entry', 'success');
add('FN-ACCOUNTS', 'An admin cannot suspend their own account', 'failed-precondition');
add('FN-ACCOUNTS', 'The last active admin cannot be suspended or demoted', 'failed-precondition');
add('FN-ACCOUNTS', 'setUserRole with an unknown role is rejected', 'invalid-argument');
add('FN-ACCOUNTS', 'setUserRole updates the custom claim and the users document together', 'success');
add('FN-ACCOUNTS', 'setUserStatus and setUserRole by a non-admin are rejected', 'permission-denied');

// Phase 2 - registry
add('FN-REGISTRY', 'registerHospital with valid data creates the hospital and an audit entry in one batch', 'success');
add('FN-REGISTRY', 'registerHospital where ICU beds exceed total beds is rejected', 'invalid-argument');
add('FN-REGISTRY', 'registerHospital with a duplicate name is rejected', 'already-exists');
add('FN-REGISTRY', 'registerAmbulance for an existing hospital succeeds', 'success');
add('FN-REGISTRY', 'registerAmbulance for a non-existent hospital is rejected', 'failed-precondition');
add('FN-REGISTRY', 'registerAmbulance with a duplicate unit id is rejected', 'already-exists');
add('FN-REGISTRY', 'stats/network counters match the real collection counts after registrations', 'success');

// Phase 4 - dispatch
add('FN-DISPATCH', 'dispatchUnit assigns an available unit, updates the incident, writes an event and an audit entry', 'success');
add('FN-DISPATCH', 'dispatchUnit on a unit that is no longer available is refused', 'failed-precondition');
add('FN-DISPATCH', 'Two dispatchers dispatching the same unit at the same time: exactly one succeeds', 'one success, one failed-precondition');
add('FN-DISPATCH', 'Two dispatchers dispatching different units to the same incident: exactly one succeeds', 'one success, one failed-precondition');
add('FN-DISPATCH', 'dispatchUnit on an already-assigned incident is refused', 'failed-precondition');
add('FN-DISPATCH', 'dispatchUnit by a non-dispatcher is rejected', 'permission-denied');
add('FN-DISPATCH', 'dispatchUnit by a suspended dispatcher is rejected', 'permission-denied');
add('FN-DISPATCH', 'onIncidentCreate suggests the nearest available unit', 'suggestion = nearest');
add('FN-DISPATCH', 'onIncidentCreate ignores units that are not available', 'suggestion excludes them');
add('FN-DISPATCH', 'onIncidentCreate with no available unit writes a null suggestion and raises an alert', 'alert created');
add('FN-DISPATCH', 'onIncidentCreate with two equidistant units picks one deterministically', 'stable choice');
add('FN-DISPATCH', 'Incident status transitions out of order (for example new to onScene) are refused', 'failed-precondition');

// Phase 3 - audit
add('FN-AUDIT', 'Every provisioning, registry and dispatch action produces exactly one audit entry with actor, action, target and server timestamp', 'success');
add('FN-AUDIT', 'A failed action (rejected by validation) produces no audit entry', 'no entry');
add('FN-AUDIT', 'Audit search by actor prefix and action filter returns correct, ordered, paginated results', 'success');

// Phase 6 - hardening
add('FN-HARDENING', 'Admin sign-in without a second factor cannot read admin data', 'permission-denied');
add('FN-HARDENING', 'Requests without a valid App Check token are rejected by Firestore, RTDB and every callable', 'rejected');
add('FN-HARDENING', 'Backup restore recreates users, hospitals and audit log intact', 'success');
add('FN-HARDENING', '100 concurrent dispatchers listening to incidents stay within the read budget', 'within budget');

export { planned };
