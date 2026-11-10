import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_dashboard/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 Hardening: Identity Platform Admin MFA & RBAC Tests', () {
    test('Admin sign-in requires exactly 6-digit TOTP code', () async {
      final auth = AuthService.instance;

      expect(
        () => auth.signInWithOperator(
          idOrEmail: 'admin@hiwonet.et',
          password: 'command-2026',
          expectedRole: 'admin',
          totpCode: '123', // Invalid length
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Admin sign-in succeeds with valid credentials and valid seeded TOTP code', () async {
      final auth = AuthService.instance;

      await auth.signInWithOperator(
        idOrEmail: 'admin@hiwonet.et',
        password: 'command-2026',
        expectedRole: 'admin',
        totpCode: '482913',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(await auth.getCurrentUserRole(), 'admin');
      expect(await auth.getCurrentUserStatus(), 'active');
      expect(auth.isMfaVerified, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isMfaVerified, isFalse);
    });

    test('Dispatcher cannot access admin console', () async {
      final auth = AuthService.instance;

      expect(
        () => auth.signInWithOperator(
          idOrEmail: 'dispatcher01',
          password: 'hiwonet-2026',
          expectedRole: 'admin',
          totpCode: '482913',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Dispatcher signs in cleanly without requiring admin TOTP', () async {
      final auth = AuthService.instance;

      await auth.signInWithOperator(
        idOrEmail: 'dispatcher01',
        password: 'hiwonet-2026',
        expectedRole: 'dispatcher',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(await auth.getCurrentUserRole(), 'dispatcher');
      expect(await auth.getCurrentUserStatus(), 'active');

      await auth.signOut();
    });

    test('Admin 3 consecutive failed MFA attempts triggers security lockout', () async {
      final auth = AuthService.instance;

      // Attempt 1: Failed
      try {
        await auth.signInWithOperator(
          idOrEmail: 'admin@hiwonet.et',
          password: 'command-2026',
          expectedRole: 'admin',
          totpCode: '111111',
        );
      } catch (e) {
        expect(e.toString(), contains('Attempt 1 of 3'));
      }

      // Attempt 2: Failed
      try {
        await auth.signInWithOperator(
          idOrEmail: 'admin@hiwonet.et',
          password: 'command-2026',
          expectedRole: 'admin',
          totpCode: '222222',
        );
      } catch (e) {
        expect(e.toString(), contains('Attempt 2 of 3'));
      }

      // Attempt 3: Triggers Security Alert Lockout
      try {
        await auth.signInWithOperator(
          idOrEmail: 'admin@hiwonet.et',
          password: 'command-2026',
          expectedRole: 'admin',
          totpCode: '333333',
        );
        fail('Should have thrown lockout exception');
      } catch (e) {
        expect(e.toString(), contains('Security Alert: 3 consecutive failed 2FA'));
      }

      // Attempt 4: Blocked while locked out
      try {
        await auth.signInWithOperator(
          idOrEmail: 'admin@hiwonet.et',
          password: 'command-2026',
          expectedRole: 'admin',
          totpCode: '482913',
        );
        fail('Should remain locked out');
      } catch (e) {
        expect(e.toString(), contains('locked'));
      }
    });
  });
}
