"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const rules_unit_testing_1 = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");
describe('Firestore Security Rules Unit Tests', () => {
    let testEnv;
    before(async () => {
        const rulesPath = path.resolve(__dirname, '../../firestore.rules');
        const rules = fs.readFileSync(rulesPath, 'utf8');
        testEnv = await (0, rules_unit_testing_1.initializeTestEnvironment)({
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
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('users').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('registrationRequests').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('hospitals').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('ambulances').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('incidents').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('auditLog').get());
        await (0, rules_unit_testing_1.assertFails)(unauthedDb.collection('alerts').get());
    });
    it('Denies client-side direct writes to all collections', async () => {
        const adminDb = testEnv.authenticatedContext('admin_user', {
            role: 'admin',
            status: 'active',
        }).firestore();
        // Even admin cannot write directly from client — Cloud Functions perform writes!
        await (0, rules_unit_testing_1.assertFails)(adminDb.collection('users').doc('u1').set({ name: 'Direct' }));
        await (0, rules_unit_testing_1.assertFails)(adminDb.collection('hospitals').add({ name: 'Direct' }));
        await (0, rules_unit_testing_1.assertFails)(adminDb.collection('ambulances').add({ unitId: 'Direct' }));
        await (0, rules_unit_testing_1.assertFails)(adminDb.collection('incidents').add({ title: 'Direct' }));
        await (0, rules_unit_testing_1.assertFails)(adminDb.collection('auditLog').add({ action: 'Direct' }));
    });
    it('Allows admins to read auditLog, registrationRequests, and users', async () => {
        const adminDb = testEnv.authenticatedContext('admin_user', {
            role: 'admin',
            status: 'active',
        }).firestore();
        await (0, rules_unit_testing_1.assertSucceeds)(adminDb.collection('auditLog').get());
        await (0, rules_unit_testing_1.assertSucceeds)(adminDb.collection('registrationRequests').get());
        await (0, rules_unit_testing_1.assertSucceeds)(adminDb.collection('users').get());
    });
    it('Denies dispatchers from reading auditLog or registrationRequests', async () => {
        const dispatcherDb = testEnv.authenticatedContext('dispatcher_1', {
            role: 'dispatcher',
            status: 'active',
        }).firestore();
        await (0, rules_unit_testing_1.assertFails)(dispatcherDb.collection('auditLog').get());
        await (0, rules_unit_testing_1.assertFails)(dispatcherDb.collection('registrationRequests').get());
    });
    it('Allows dispatchers to read incidents, ambulances, and hospitals', async () => {
        const dispatcherDb = testEnv.authenticatedContext('dispatcher_1', {
            role: 'dispatcher',
            status: 'active',
        }).firestore();
        await (0, rules_unit_testing_1.assertSucceeds)(dispatcherDb.collection('incidents').get());
        await (0, rules_unit_testing_1.assertSucceeds)(dispatcherDb.collection('ambulances').get());
        await (0, rules_unit_testing_1.assertSucceeds)(dispatcherDb.collection('hospitals').get());
        await (0, rules_unit_testing_1.assertSucceeds)(dispatcherDb.collection('alerts').get());
    });
    it('Locks out suspended users immediately', async () => {
        const suspendedDb = testEnv.authenticatedContext('dispatcher_suspended', {
            role: 'dispatcher',
            status: 'suspended',
        }).firestore();
        await (0, rules_unit_testing_1.assertFails)(suspendedDb.collection('incidents').get());
        await (0, rules_unit_testing_1.assertFails)(suspendedDb.collection('ambulances').get());
        await (0, rules_unit_testing_1.assertFails)(suspendedDb.collection('hospitals').get());
    });
});
//# sourceMappingURL=rules.test.js.map