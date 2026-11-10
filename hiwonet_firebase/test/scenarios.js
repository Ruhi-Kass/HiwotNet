// Single source of truth for every security-rules scenario.
//
// The same table drives (1) the vitest suite, (2) the exported catalog
// (testcases/catalog.json + TEST_CASES.md) and (3) the testCases collection
// uploaded to Firestore, so the documentation can never drift from what is
// actually executed.
//
// IDs are assigned in order per area (TC-<AREA>-NNN). Only APPEND new
// scenarios to an area; inserting in the middle would renumber existing IDs.

export const ACTORS = {
  anonymous: { uid: null, claims: {}, label: 'Anonymous visitor' },
  unprovisioned: { uid: 'u-new', claims: {}, label: 'Signed-in user with no role (pending or unprovisioned)' },
  caller: { uid: 'u-caller', claims: { role: 'caller' }, label: 'Caller' },
  crewA: { uid: 'u-crewA', claims: { role: 'crew', unitId: 'AMB-4712' }, label: 'Crew member of AMB-4712' },
  crewB: { uid: 'u-crewB', claims: { role: 'crew', unitId: 'AMB-4713' }, label: 'Crew member of AMB-4713' },
  hospitalStaff: { uid: 'u-hosp', claims: { role: 'hospitalStaff' }, label: 'Hospital staff' },
  dispatcher: { uid: 'u-disp', claims: { role: 'dispatcher' }, label: 'Dispatcher' },
  admin: { uid: 'u-admin', claims: { role: 'admin' }, label: 'Admin' },
  suspendedDispatcher: { uid: 'u-susp', claims: { role: 'dispatcher', suspended: true }, label: 'Suspended dispatcher (stale token)' },
  suspendedCrewA: { uid: 'u-crewA', claims: { role: 'crew', unitId: 'AMB-4712', suspended: true }, label: 'Suspended crew member of AMB-4712' },
};

const ALL = Object.keys(ACTORS);

export const scenarios = [];
const counters = {};

function add(area, s) {
  counters[area] = (counters[area] || 0) + 1;
  scenarios.push({
    id: `TC-${area}-${String(counters[area]).padStart(3, '0')}`,
    area,
    ...s,
  });
}

const verb = (expect) => (expect === 'allow' ? 'can' : 'cannot');

// ---------------------------------------------------------------------------
// FS-READ: who may read which collection (full actor x document matrix)
// ---------------------------------------------------------------------------
const OPS = ['dispatcher', 'admin'];
const readMatrix = [
  ['hospitals/h1', OPS],
  ['ambulances/AMB-4712', ['dispatcher', 'admin', 'crewA']], // crewA is assigned to it
  ['incidents/inc1', OPS],
  ['incidents/inc1/events/e1', OPS],
  ['alerts/al1', OPS],
  ['auditLog/a1', ['admin']],
  ['stats/network', ['admin']],
  ['registrationRequests/r1', ['admin']],
  ['users/u-disp', ['admin', 'dispatcher']], // dispatcher is u-disp: own profile
  ['users/u-admin', ['admin']],
  ['users/u-caller', ['admin', 'caller']], // caller is u-caller: own profile
  ['testRuns/run1', ['admin']],
  ['testCases/tc1', ['admin']],
  ['unknownCollection/x', []], // deny by default, even for admin
];

for (const [target, allowed] of readMatrix) {
  for (const actor of ALL) {
    const expect = allowed.includes(actor) ? 'allow' : 'deny';
    add('FS-READ', {
      store: 'firestore',
      op: 'get',
      target,
      actor,
      expect,
      title: `${ACTORS[actor].label} ${verb(expect)} read ${target}`,
    });
  }
}

// ---------------------------------------------------------------------------
// FS-WRITE: no client may create documents directly (functions do that)
// ---------------------------------------------------------------------------
const createTargets = [
  'users/u-x',
  'registrationRequests/r-new',
  'hospitals/h-new',
  'ambulances/AMB-9999',
  'incidents/inc-new',
  'incidents/inc1/events/e-new',
  'auditLog/a-new',
  'alerts/al-new',
  'stats/other',
  'testRuns/run-new',
  'unknownCollection/new',
];

for (const target of createTargets) {
  for (const actor of ALL) {
    add('FS-WRITE', {
      store: 'firestore',
      op: 'create',
      target,
      data: { name: 'x', status: 'active' },
      actor,
      expect: 'deny',
      title: `${ACTORS[actor].label} cannot create ${target}`,
    });
  }
}

// Updates and deletes of existing documents are also function-only.
const mutableTargets = [
  'users/u-disp',
  'hospitals/h1',
  'ambulances/AMB-4712',
  'incidents/inc1',
  'auditLog/a1',
  'alerts/al1',
  'stats/network',
  'registrationRequests/r1',
];

for (const actor of ['dispatcher', 'admin', 'caller']) {
  for (const target of mutableTargets) {
    add('FS-WRITE', {
      store: 'firestore',
      op: 'update',
      target,
      data: { touched: true },
      actor,
      expect: 'deny',
      title: `${ACTORS[actor].label} cannot update ${target}`,
    });
    add('FS-WRITE', {
      store: 'firestore',
      op: 'delete',
      target,
      actor,
      expect: 'deny',
      title: `${ACTORS[actor].label} cannot delete ${target}`,
    });
  }
}

// ---------------------------------------------------------------------------
// FS-ESCALATION: privilege-escalation and tampering attempts
// ---------------------------------------------------------------------------
const escalation = [
  ['caller', 'update', 'users/u-caller', { role: 'admin' }, 'Caller cannot promote themselves to admin by editing their profile'],
  ['dispatcher', 'update', 'users/u-disp', { role: 'admin' }, 'Dispatcher cannot promote themselves to admin'],
  ['dispatcher', 'update', 'users/u-disp', { status: 'active', name: 'renamed' }, 'Dispatcher cannot edit their own profile fields'],
  ['unprovisioned', 'create', 'users/u-new', { role: 'admin', status: 'active' }, 'Unprovisioned user cannot create their own admin profile'],
  ['unprovisioned', 'create', 'users/u-new', { role: 'dispatcher', status: 'active' }, 'Unprovisioned user cannot create their own dispatcher profile'],
  ['anonymous', 'create', 'registrationRequests/r-evil', { status: 'approved', role: 'admin' }, 'Anonymous visitor cannot self-approve a registration request'],
  ['admin', 'update', 'users/u-disp', { status: 'suspended' }, 'Admin cannot suspend a user by direct write (must use the function that also disables Auth)'],
  ['admin', 'update', 'users/u-disp', { role: 'crew' }, 'Admin cannot change a role by direct write (must use the function that updates the claim)'],
  ['admin', 'update', 'auditLog/a1', { actor: 'someone else' }, 'Admin cannot edit an audit entry'],
  ['admin', 'delete', 'auditLog/a1', undefined, 'Admin cannot delete an audit entry'],
  ['admin', 'create', 'auditLog/a-forged', { actor: 'Meron A. (Admin)', action: 'signIn' }, 'Admin cannot forge an audit entry from the client'],
  ['dispatcher', 'update', 'incidents/inc1', { status: 'closed' }, 'Dispatcher cannot close an incident by direct write'],
  ['dispatcher', 'update', 'ambulances/AMB-4712', { status: 'enRoute' }, 'Dispatcher cannot dispatch a unit by direct write (must use the transactional function)'],
  ['dispatcher', 'update', 'hospitals/h1', { beds: 9999 }, 'Dispatcher cannot change hospital capacity'],
  ['suspendedDispatcher', 'get', 'incidents/inc1', undefined, 'Suspended dispatcher with a still-valid token cannot read incidents'],
  ['suspendedDispatcher', 'get', 'hospitals/h1', undefined, 'Suspended dispatcher with a still-valid token cannot read hospitals'],
  ['hospitalStaff', 'get', 'incidents/inc1', undefined, 'Hospital staff cannot read incidents'],
  ['caller', 'get', 'ambulances/AMB-4712', undefined, 'Caller cannot read ambulance records'],
];

for (const [actor, op, target, data, title] of escalation) {
  add('FS-ESCALATION', { store: 'firestore', op, target, data, actor, expect: 'deny', title });
}

// ---------------------------------------------------------------------------
// FS-CREW: the one direct write clients have (own ambulance status)
// ---------------------------------------------------------------------------
const crew = [
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'onScene' }, 'allow', 'Crew can set the status of their own ambulance to onScene'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'enRoute' }, 'allow', 'Crew can set the status of their own ambulance to enRoute'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'transporting' }, 'allow', 'Crew can set the status of their own ambulance to transporting'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'offline' }, 'allow', 'Crew can set the status of their own ambulance to offline'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'hacked' }, 'deny', 'Crew cannot set an unknown status value'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: '' }, 'deny', 'Crew cannot set an empty status'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 42 }, 'deny', 'Crew cannot set a non-string status'],
  ['crewA', 'update', 'ambulances/AMB-4712', { crewUid: 'u-crewB' }, 'deny', 'Crew cannot reassign their unit to another crew member'],
  ['crewA', 'update', 'ambulances/AMB-4712', { homeBaseId: 'h-other' }, 'deny', 'Crew cannot change their unit home base'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'onScene', crewUid: 'u-crewA2' }, 'deny', 'Crew cannot smuggle an extra field alongside a valid status'],
  ['crewA', 'update', 'ambulances/AMB-4712', { status: 'onScene', activeIncidentId: 'inc1' }, 'deny', 'Crew cannot set the active incident directly'],
  ['crewA', 'update', 'ambulances/AMB-4713', { status: 'onScene' }, 'deny', "Crew cannot change another crew's ambulance status"],
  ['crewB', 'update', 'ambulances/AMB-4712', { status: 'onScene' }, 'deny', "Crew B cannot change crew A's ambulance status"],
  ['crewA', 'delete', 'ambulances/AMB-4712', undefined, 'deny', 'Crew cannot delete their ambulance'],
  ['crewA', 'create', 'ambulances/AMB-5000', { crewUid: 'u-crewA', status: 'available' }, 'deny', 'Crew cannot register a new ambulance'],
  ['suspendedCrewA', 'update', 'ambulances/AMB-4712', { status: 'onScene' }, 'deny', 'Suspended crew member cannot update their ambulance'],
  ['caller', 'update', 'ambulances/AMB-4712', { status: 'onScene' }, 'deny', 'Caller cannot update an ambulance status'],
  ['hospitalStaff', 'update', 'ambulances/AMB-4712', { status: 'onScene' }, 'deny', 'Hospital staff cannot update an ambulance status'],
  ['crewA', 'get', 'ambulances/AMB-4712', undefined, 'allow', 'Crew can read their own ambulance'],
  ['crewA', 'get', 'ambulances/AMB-4713', undefined, 'deny', "Crew cannot read another crew's ambulance"],
  ['crewA', 'get', 'hospitals/h1', undefined, 'deny', 'Crew cannot read the hospital registry'],
  ['crewA', 'get', 'incidents/inc1', undefined, 'deny', 'Crew cannot read incidents directly'],
];

for (const [actor, op, target, data, expect, title] of crew) {
  add('FS-CREW', { store: 'firestore', op, target, data, actor, expect, title });
}

// ---------------------------------------------------------------------------
// FS-QUERY: list queries must be provably within what the rules allow
// ---------------------------------------------------------------------------
const queries = [
  ['dispatcher', 'incidents', (c) => c, 'allow', 'Dispatcher can list all incidents', 'unfiltered'],
  ['dispatcher', 'incidents', (c) => c.where('status', '==', 'new'), 'allow', 'Dispatcher can list new incidents', "status == 'new'"],
  ['dispatcher', 'hospitals', (c) => c, 'allow', 'Dispatcher can list hospitals', 'unfiltered'],
  ['dispatcher', 'ambulances', (c) => c, 'allow', 'Dispatcher can list all ambulances', 'unfiltered'],
  ['dispatcher', 'alerts', (c) => c, 'allow', 'Dispatcher can list alerts', 'unfiltered'],
  ['admin', 'auditLog', (c) => c.orderBy('ts', 'desc').limit(50), 'allow', 'Admin can list the latest 50 audit entries', 'orderBy ts desc, limit 50'],
  ['admin', 'users', (c) => c, 'allow', 'Admin can list all users', 'unfiltered'],
  ['admin', 'registrationRequests', (c) => c.where('status', '==', 'pending'), 'allow', 'Admin can list pending registration requests', "status == 'pending'"],
  ['dispatcher', 'auditLog', (c) => c, 'deny', 'Dispatcher cannot list the audit log', 'unfiltered'],
  ['dispatcher', 'users', (c) => c, 'deny', 'Dispatcher cannot list all users', 'unfiltered'],
  ['dispatcher', 'registrationRequests', (c) => c, 'deny', 'Dispatcher cannot list registration requests', 'unfiltered'],
  ['caller', 'incidents', (c) => c, 'deny', 'Caller cannot list incidents', 'unfiltered'],
  ['anonymous', 'hospitals', (c) => c, 'deny', 'Anonymous visitor cannot list hospitals', 'unfiltered'],
  ['hospitalStaff', 'ambulances', (c) => c, 'deny', 'Hospital staff cannot list ambulances', 'unfiltered'],
  ['suspendedDispatcher', 'incidents', (c) => c, 'deny', 'Suspended dispatcher cannot list incidents', 'unfiltered'],
  ['crewA', 'ambulances', (c) => c.where('crewUid', '==', 'u-crewA'), 'allow', 'Crew can list ambulances filtered to their own uid', "crewUid == own uid"],
  ['crewA', 'ambulances', (c) => c, 'deny', 'Crew cannot list all ambulances', 'unfiltered'],
  ['crewA', 'ambulances', (c) => c.where('crewUid', '==', 'u-crewB'), 'deny', "Crew cannot list another crew member's ambulances", "crewUid == another uid"],
  ['crewA', 'incidents', (c) => c, 'deny', 'Crew cannot list incidents', 'unfiltered'],
];

for (const [actor, target, query, expect, title, queryDesc] of queries) {
  add('FS-QUERY', { store: 'firestore', op: 'list', target, query, queryDesc, actor, expect, title });
}

// ---------------------------------------------------------------------------
// RTDB-READ: live ambulance positions
// ---------------------------------------------------------------------------
for (const actor of ALL) {
  const expect = ['dispatcher', 'admin'].includes(actor) ? 'allow' : 'deny';
  add('RTDB-READ', {
    store: 'rtdb',
    op: 'get',
    target: 'positions',
    actor,
    expect,
    title: `${ACTORS[actor].label} ${verb(expect)} read all live positions`,
  });
}

for (const actor of ['dispatcher', 'admin']) {
  add('RTDB-READ', {
    store: 'rtdb',
    op: 'get',
    target: 'positions/AMB-4712',
    actor,
    expect: 'allow',
    title: `${ACTORS[actor].label} can read one unit position`,
  });
}

for (const actor of ['admin', 'dispatcher']) {
  add('RTDB-READ', {
    store: 'rtdb',
    op: 'get',
    target: '/',
    actor,
    expect: 'deny',
    title: `${ACTORS[actor].label} cannot read the database root`,
  });
}

// ---------------------------------------------------------------------------
// RTDB-WRITE: who may publish positions, and for which unit
// ---------------------------------------------------------------------------
const fix = () => ({ lat: 9.03, lng: 38.74, ts: Date.now() });

add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'crewA', expect: 'allow', title: 'Crew can publish the position of their own unit' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4713', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'crewA', expect: 'deny', title: "Crew cannot publish another unit's position" });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'crewB', expect: 'deny', title: "Crew B cannot publish crew A's unit position" });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'suspendedCrewA', expect: 'deny', title: 'Suspended crew member cannot publish a position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'dispatcher', expect: 'deny', title: 'Dispatcher cannot publish a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'admin', expect: 'deny', title: 'Admin cannot publish a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'caller', expect: 'deny', title: 'Caller cannot publish a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'anonymous', expect: 'deny', title: 'Anonymous visitor cannot publish a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data: fix, dataDesc: '{lat 9.03, lng 38.74, ts now}', actor: 'unprovisioned', expect: 'deny', title: 'Unprovisioned user cannot publish a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'remove', target: 'positions/AMB-4712', actor: 'crewA', expect: 'allow', title: 'Crew can clear their own unit position (going offline)' });
add('RTDB-WRITE', { store: 'rtdb', op: 'remove', target: 'positions/AMB-4712', actor: 'dispatcher', expect: 'deny', title: 'Dispatcher cannot delete a unit position' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'unknownNode/x', data: () => ({ a: 1 }), dataDesc: '{a: 1}', actor: 'admin', expect: 'deny', title: 'Admin cannot write outside the positions node' });
add('RTDB-WRITE', { store: 'rtdb', op: 'set', target: 'positions', data: () => ({ 'AMB-4712': fix() }), dataDesc: 'whole positions node', actor: 'crewA', expect: 'deny', title: 'Crew cannot overwrite the whole positions node' });

// ---------------------------------------------------------------------------
// RTDB-VALIDATION: shape and range checks on a position payload
// ---------------------------------------------------------------------------
const pos = (extra, drop = []) => () => {
  const base = { lat: 9.03, lng: 38.74, ts: Date.now(), ...extra };
  for (const k of drop) delete base[k];
  return base;
};

const validation = [
  [pos({ lat: 90 }), 'allow', 'Latitude 90 (upper bound) is accepted', '{lat: 90}'],
  [pos({ lat: -90 }), 'allow', 'Latitude -90 (lower bound) is accepted', '{lat: -90}'],
  [pos({ lng: 180 }), 'allow', 'Longitude 180 (upper bound) is accepted', '{lng: 180}'],
  [pos({ lng: -180 }), 'allow', 'Longitude -180 (lower bound) is accepted', '{lng: -180}'],
  [pos({ lat: 0, lng: 0 }), 'allow', 'Latitude 0 / longitude 0 is accepted', '{lat: 0, lng: 0}'],
  [pos({ ts: Date.now() + 30000 }), 'allow', 'A timestamp 30s ahead (clock skew) is accepted', '{ts: now + 30s}'],
  [pos({ lat: 90.0001 }), 'deny', 'Latitude just above 90 is rejected', '{lat: 90.0001}'],
  [pos({ lat: -90.0001 }), 'deny', 'Latitude just below -90 is rejected', '{lat: -90.0001}'],
  [pos({ lat: 91 }), 'deny', 'Latitude 91 is rejected', '{lat: 91}'],
  [pos({ lng: 180.0001 }), 'deny', 'Longitude just above 180 is rejected', '{lng: 180.0001}'],
  [pos({ lng: -181 }), 'deny', 'Longitude -181 is rejected', '{lng: -181}'],
  [pos({ lat: '9.03' }), 'deny', 'Latitude as a string is rejected', "{lat: '9.03'}"],
  [pos({ lng: '38.74' }), 'deny', 'Longitude as a string is rejected', "{lng: '38.74'}"],
  [pos({ lat: null }), 'deny', 'A null latitude is rejected', '{lat: null}'],
  [pos({ ts: 'now' }), 'deny', 'A string timestamp is rejected', "{ts: 'now'}"],
  [pos({ ts: Date.now() + 3600000 }), 'deny', 'A timestamp one hour in the future is rejected', '{ts: now + 1h}'],
  [pos({}, ['ts']), 'deny', 'A payload missing ts is rejected', 'no ts'],
  [pos({}, ['lat']), 'deny', 'A payload missing lat is rejected', 'no lat'],
  [pos({}, ['lng']), 'deny', 'A payload missing lng is rejected', 'no lng'],
  [pos({ speed: 80 }), 'deny', 'An unexpected extra field is rejected', '{speed: 80}'],
  [pos({ unitId: 'AMB-4713' }), 'deny', 'A spoofed unitId field is rejected', "{unitId: 'AMB-4713'}"],
  // Realtime Database treats set({}) as a delete, and validation is not run
  // on deletes, so this equals "crew clears their own position" (allowed).
  [() => ({}), 'allow', 'An empty object is treated as a delete of the crew member\'s own position', '{}'],
  [() => 'AMB-4712 is here', 'deny', 'A bare string instead of an object is rejected', 'string payload'],
];

for (const [data, expect, title, dataDesc] of validation) {
  add('RTDB-VALIDATION', { store: 'rtdb', op: 'set', target: 'positions/AMB-4712', data, dataDesc, actor: 'crewA', expect, title });
}

// ---------------------------------------------------------------------------
// Helpers consumed by the test file and the catalog exporter
// ---------------------------------------------------------------------------
export function toCatalogEntry(s) {
  return {
    id: s.id,
    area: s.area,
    status: 'automated',
    store: s.store,
    actor: ACTORS[s.actor].label,
    operation: s.op,
    target: s.target,
    ...(s.queryDesc ? { query: s.queryDesc } : {}),
    ...(s.dataDesc ? { payload: s.dataDesc } : s.data && typeof s.data !== 'function' ? { payload: JSON.stringify(s.data) } : {}),
    expected: s.expect,
    title: s.title,
  };
}
