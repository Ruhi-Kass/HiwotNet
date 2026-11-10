import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_dashboard/services/auth_service.dart';
import 'package:dispatch_dashboard/services/admin_repository.dart';
import 'package:dispatch_dashboard/models/admin_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dispatcher Workflow & Profile Sync Tests', () {
    test('Default dispatcher has valid name, callsign, and employee ID', () async {
      final auth = AuthService.instance;
      await auth.signInWithOperator(
        idOrEmail: 'dispatcher01',
        password: 'hiwonet-2026',
        expectedRole: 'dispatcher',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserName, isNotEmpty);
      expect(auth.currentEmployeeId, isNotEmpty);
      expect(auth.currentCallsign, isNotEmpty);
      expect(auth.currentDispatchCenter, contains('Addis Ababa'));

      await auth.signOut();
    });

    test('Updating profile notifies listeners and syncs data', () async {
      final auth = AuthService.instance;
      await auth.signInWithOperator(
        idOrEmail: 'dispatcher01',
        password: 'hiwonet-2026',
        expectedRole: 'dispatcher',
      );

      int notifyCount = 0;
      void listener() => notifyCount++;
      auth.profileUpdateNotifier.addListener(listener);

      auth.updateCurrentUserProfile(
        fullName: 'Selam Tesfaye',
        photoUrl: 'preset:ST:4282337097',
        radioCallsign: 'DELTA-44',
        dispatchCenter: 'Bole Command Center',
      );

      expect(notifyCount, greaterThan(0));
      expect(auth.currentUserName, 'Selam Tesfaye');
      expect(auth.currentUserPhoto, 'preset:ST:4282337097');
      expect(auth.currentCallsign, 'DELTA-44');
      expect(auth.currentDispatchCenter, 'Bole Command Center');

      auth.profileUpdateNotifier.removeListener(listener);
      await auth.signOut();
    });

    test('Admin approval removes request from pending and adds user to staff', () async {
      final adminRepo = AdminRepository.instance;
      final auth = AuthService.instance;

      final testEmpId = adminRepo.generateUniqueEmployeeId();
      final testCallsign = adminRepo.generateUniqueRadioCallsign();

      await adminRepo.submitRegistration(
        fullName: 'Yonas Kebede',
        employeeId: testEmpId,
        dispatchCenter: 'Kirkos Command Center',
        radioCallsign: testCallsign,
        email: 'yonas.k@addisababa.gov.et',
        password: 'password-1234',
      );

      // Verify it appears in pending requests
      final pendingInitial = await adminRepo.streamRegistrationRequests().first;
      final match = pendingInitial.firstWhere((r) => r.email == 'yonas.k@addisababa.gov.et');
      expect(match, isNotNull);

      // Admin approves request
      await adminRepo.approveRegistration(requestId: match.id, role: 'dispatcher');

      // Verify request is removed from pending
      final pendingAfter = await adminRepo.streamRegistrationRequests().first;
      expect(pendingAfter.any((r) => r.id == match.id), isFalse);

      // Verify newly approved dispatcher is in active users list
      final usersAfter = await adminRepo.streamUsers().first;
      final userAccount = usersAfter.firstWhere((u) => u.name == 'Yonas Kebede');
      expect(userAccount.role, AccountRole.dispatcher);
      expect(userAccount.status, AccountStatus.active);

      // Verify dispatcher can now sign in immediately
      await auth.signInWithOperator(
        idOrEmail: 'yonas.k@addisababa.gov.et',
        password: 'password-1234',
        expectedRole: 'dispatcher',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserName, 'Yonas Kebede');
      expect(auth.currentEmployeeId, testEmpId);
      expect(auth.currentCallsign, testCallsign);

      await auth.signOut();
    });

    test('Duplicate dispatcher submissions are rejected upfront', () async {
      final adminRepo = AdminRepository.instance;

      // Check conflict detection for default dispatcher
      final conflict = adminRepo.findDispatcherConflict(
        email: AuthService.demoDispatcherEmail,
        fullName: 'New Person',
        employeeId: 'DSP-9999',
        radioCallsign: 'NEW-99',
      );

      expect(conflict, isNotNull);
      expect(conflict, contains('already registered and active'));
    });

    test('Dispatcher can update photo while credentials remain intact and view-only', () async {
      final auth = AuthService.instance;
      await auth.signInWithOperator(
        idOrEmail: 'dispatcher01',
        password: 'hiwonet-2026',
        expectedRole: 'dispatcher',
      );

      final initialName = auth.currentUserName;
      final initialCallsign = auth.currentCallsign;
      final initialCenter = auth.currentDispatchCenter;
      final initialEmpId = auth.currentEmployeeId;

      // Dispatcher uploads a new photo
      auth.updateCurrentUserProfile(photoUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

      // Credentials remain unchanged
      expect(auth.currentUserName, initialName);
      expect(auth.currentCallsign, initialCallsign);
      expect(auth.currentDispatchCenter, initialCenter);
      expect(auth.currentEmployeeId, initialEmpId);
      expect(auth.currentUserPhoto, isNotEmpty);

      await auth.signOut();
    });

    test('Admin role detection correctly differentiates admin from dispatcher', () async {
      final auth = AuthService.instance;

      // Dispatcher sign in
      await auth.signInWithOperator(
        idOrEmail: 'dispatcher01',
        password: 'hiwonet-2026',
        expectedRole: 'dispatcher',
      );
      expect(auth.isAdmin, isFalse);
      await auth.signOut();

      // Admin sign in
      await auth.signInWithOperator(
        idOrEmail: AuthService.demoAdminEmail,
        password: AuthService.demoAdminPassword,
        expectedRole: 'admin',
        totpCode: AuthService.demoAdminOtp,
      );
      expect(auth.isAdmin, isTrue);
      await auth.signOut();
    });
  });
}
