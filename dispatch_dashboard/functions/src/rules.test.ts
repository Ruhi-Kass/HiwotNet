import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';

describe('Firestore Security Rules Unit Tests', () => {
  let testEnv: RulesTestEnvironment;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: 'hiwotnet-rules-test',
      firestore: {
        rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('Denies unauthenticated access to all collections', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();

    await assertFails(unauthedDb.collection('users').get());
    await assertFails(unauthedDb.collection('registrationRequests').get());
    await assertFails(unauthedDb.collection('hospitals').get());
    await assertFails(unauthedDb.collection('ambulances').get());
    await assertFails(unauthedDb.collection('incidents').get());
    await assertFails(unauthedDb.collection('auditLog').get());
    await assertFails(unauthedDb.collection('alerts').get());
  });

  it('Denies client-side direct writes to all collections', async () => {
    const adminDb = testEnv.authenticatedContext('admin_user', {
      role: 'admin',
      status: 'active',
    }).firestore();

    // Even admin cannot write directly from client — Cloud Functions perform writes!
    await assertFails(adminDb.collection('users').doc('u1').set({ name: 'Direct' }));
    await assertFails(adminDb.collection('hospitals').add({ name: 'Direct' }));
    await assertFails(adminDb.collection('ambulances').add({ unitId: 'Direct' }));
    await assertFails(adminDb.collection('incidents').add({ title: 'Direct' }));
    await assertFails(adminDb.collection('auditLog').add({ action: 'Direct' }));
  });

  it('Allows admins to read auditLog, registrationRequests, and users', async () => {
    const adminDb = testEnv.authenticatedContext('admin_user', {
      role: 'admin',
      status: 'active',
    }).firestore();

    await assertSucceeds(adminDb.collection('auditLog').get());
    await assertSucceeds(adminDb.collection('registrationRequests').get());
    await assertSucceeds(adminDb.collection('users').get());
  });

  it('Denies dispatchers from reading auditLog or registrationRequests', async () => {
    const dispatcherDb = testEnv.authenticatedContext('dispatcher_1', {
      role: 'dispatcher',
      status: 'active',
    }).firestore();

    await assertFails(dispatcherDb.collection('auditLog').get());
    await assertFails(dispatcherDb.collection('registrationRequests').get());
  });

  it('Allows dispatchers to read incidents, ambulances, and hospitals', async () => {
    const dispatcherDb = testEnv.authenticatedContext('dispatcher_1', {
      role: 'dispatcher',
      status: 'active',
    }).firestore();

    await assertSucceeds(dispatcherDb.collection('incidents').get());
    await assertSucceeds(dispatcherDb.collection('ambulances').get());
    await assertSucceeds(dispatcherDb.collection('hospitals').get());
    await assertSucceeds(dispatcherDb.collection('alerts').get());
  });

  it('Locks out suspended users immediately', async () => {
    const suspendedDb = testEnv.authenticatedContext('dispatcher_suspended', {
      role: 'dispatcher',
      status: 'suspended',
    }).firestore();

    await assertFails(suspendedDb.collection('incidents').get());
    await assertFails(suspendedDb.collection('ambulances').get());
    await assertFails(suspendedDb.collection('hospitals').get());
  });
});
