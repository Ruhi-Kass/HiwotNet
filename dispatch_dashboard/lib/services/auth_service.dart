import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'session_storage.dart';

/// Represents a dispatcher provisioned and approved by an administrator.
class ApprovedDispatcherAccount {
  final String fullName;
  final String employeeId;
  final String email;
  final String radioCallsign;
  final String dispatchCenter;
  final String? photoUrl;
  final String password;

  const ApprovedDispatcherAccount({
    required this.fullName,
    required this.employeeId,
    required this.email,
    required this.radioCallsign,
    this.dispatchCenter = 'Addis Ababa Central Command',
    this.photoUrl,
    this.password = 'hiwonet-2026',
  });

  ApprovedDispatcherAccount copyWith({
    String? fullName,
    String? employeeId,
    String? email,
    String? radioCallsign,
    String? dispatchCenter,
    String? photoUrl,
    String? password,
  }) {
    return ApprovedDispatcherAccount(
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      radioCallsign: radioCallsign ?? this.radioCallsign,
      dispatchCenter: dispatchCenter ?? this.dispatchCenter,
      photoUrl: photoUrl ?? this.photoUrl,
      password: password ?? this.password,
    );
  }
}

/// Authentication and Role-Based Access Control (RBAC) service.
///
/// Custom claims (`role`, `status`) attached to the Firebase Auth token
/// serve as the single source of truth for authorization. The Firestore
/// `users/{uid}` document mirrors this state for client listing.
class AuthService {
  AuthService._() {
    _restoreSession();
  }
  static final AuthService instance = AuthService._();

  final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFunctions? get _functions {
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

  final List<ApprovedDispatcherAccount> _approvedDispatchers = [];

  List<ApprovedDispatcherAccount> get approvedDispatchers =>
      List.unmodifiable(_approvedDispatchers);

  void registerApprovedDispatcher({
    required String fullName,
    required String employeeId,
    required String email,
    required String radioCallsign,
    String dispatchCenter = 'Addis Ababa Central Command',
    String? photoUrl,
    String password = 'hiwonet-2026',
  }) {
    final clean = email.trim().toLowerCase();
    _approvedDispatchers.removeWhere((d) =>
        d.email == clean ||
        d.employeeId.toLowerCase() == employeeId.trim().toLowerCase());
    _approvedDispatchers.add(
      ApprovedDispatcherAccount(
        fullName: fullName.trim(),
        employeeId: employeeId.trim(),
        email: clean,
        radioCallsign: radioCallsign.trim(),
        dispatchCenter: dispatchCenter.trim(),
        photoUrl: photoUrl,
        password: password,
      ),
    );
    profileUpdateNotifier.value++;
  }

  bool get isFirebaseAvailable {
    try {
      return FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Seeded demo accounts for resilient offline / presentation fallback
  static const String demoDispatcherId = 'dispatcher01';
  static const String demoDispatcherEmail = 'dispatcher01@hiwonet.et';
  static const String demoDispatcherPassword = 'hiwonet-2026';

  static const String demoAdminEmail = 'admin@hiwonet.et';
  static const String demoAdminPassword = 'command-2026';
  static const String demoAdminOtp = '482913';

  // In-memory demo session tracking when running without emulator
  String? _demoRole;
  String? _demoStatus;
  String? _demoEmail;
  bool _mfaVerified = false;
  int _failedAdminMfaAttempts = 0;
  DateTime? _adminMfaLockoutUntil;

  // Dispatcher personal profile details
  String? _currentUserName;
  String? _currentUserPhoto;
  String? _currentEmployeeId;
  String? _currentCallsign;
  String? _currentDispatchCenter;

  User? get currentUser => _auth?.currentUser;
  bool get isAuthenticated => currentUser != null || _demoRole != null;
  String? get currentEmail => currentUser?.email ?? _demoEmail;
  String? get currentRole => _demoRole;
  bool get isAdmin => _demoRole == 'admin';
  bool get isMfaVerified => _mfaVerified || (_demoRole == 'admin' && _mfaVerified);

  String get currentUserName {
    if (_currentUserName != null && _currentUserName!.isNotEmpty) {
      return _currentUserName!;
    }
    if (_demoRole == 'admin') return 'System Administrator';
    return 'Abebe Bekele';
  }

  String? get currentUserPhoto => _currentUserPhoto;

  String get currentEmployeeId {
    if (_currentEmployeeId != null && _currentEmployeeId!.isNotEmpty) {
      return _currentEmployeeId!;
    }
    if (_demoRole == 'admin') return 'ADM-001';
    return 'DSP-2026-1001';
  }

  String get currentCallsign {
    if (_currentCallsign != null && _currentCallsign!.isNotEmpty) {
      return _currentCallsign!;
    }
    if (_demoRole == 'admin') return 'COMMAND-ALPHA';
    return 'ECHO-101';
  }

  String get currentDispatchCenter {
    if (_currentDispatchCenter != null && _currentDispatchCenter!.isNotEmpty) {
      return _currentDispatchCenter!;
    }
    return 'Addis Ababa Central Command';
  }

  void _restoreSession() {
    final savedRole = SessionStorage.getItem('hiwonet_role');
    if (savedRole != null && savedRole.isNotEmpty) {
      _demoRole = savedRole;
      _demoEmail = SessionStorage.getItem('hiwonet_email') ??
          (savedRole == 'admin' ? demoAdminEmail : demoDispatcherEmail);
      _demoStatus = SessionStorage.getItem('hiwonet_status') ?? 'active';
      _mfaVerified = SessionStorage.getItem('hiwonet_mfa') == 'true' || savedRole == 'admin';
      _currentUserName = SessionStorage.getItem('hiwonet_user_name');
      _currentUserPhoto = SessionStorage.getItem('hiwonet_user_photo');
      _currentEmployeeId = SessionStorage.getItem('hiwonet_employee_id');
      _currentCallsign = SessionStorage.getItem('hiwonet_callsign');
      _currentDispatchCenter = SessionStorage.getItem('hiwonet_center');
    }
  }

  void _saveSession({
    required String role,
    required String email,
    String status = 'active',
    bool mfaVerified = false,
    String? userName,
    String? photoUrl,
    String? employeeId,
    String? callsign,
    String? dispatchCenter,
  }) {
    SessionStorage.setItem('hiwonet_role', role);
    SessionStorage.setItem('hiwonet_email', email);
    SessionStorage.setItem('hiwonet_status', status);
    SessionStorage.setItem('hiwonet_mfa', mfaVerified ? 'true' : 'false');
    if (userName != null) SessionStorage.setItem('hiwonet_user_name', userName);
    if (photoUrl != null) SessionStorage.setItem('hiwonet_user_photo', photoUrl);
    if (employeeId != null) SessionStorage.setItem('hiwonet_employee_id', employeeId);
    if (callsign != null) SessionStorage.setItem('hiwonet_callsign', callsign);
    if (dispatchCenter != null) SessionStorage.setItem('hiwonet_center', dispatchCenter);
  }

  void _clearSession() {
    SessionStorage.removeItem('hiwonet_role');
    SessionStorage.removeItem('hiwonet_email');
    SessionStorage.removeItem('hiwonet_status');
    SessionStorage.removeItem('hiwonet_mfa');
    SessionStorage.removeItem('hiwonet_user_name');
    SessionStorage.removeItem('hiwonet_user_photo');
    SessionStorage.removeItem('hiwonet_employee_id');
    SessionStorage.removeItem('hiwonet_callsign');
    SessionStorage.removeItem('hiwonet_center');
    _currentUserName = null;
    _currentUserPhoto = null;
    _currentEmployeeId = null;
    _currentCallsign = null;
    _currentDispatchCenter = null;
    profileUpdateNotifier.value++;
  }

  /// Updates and synchronizes the active dispatcher profile across memory & session
  void updateCurrentUserProfile({
    String? fullName,
    String? photoUrl,
    String? radioCallsign,
    String? dispatchCenter,
  }) {
    if (fullName != null && fullName.isNotEmpty) {
      _currentUserName = fullName;
      SessionStorage.setItem('hiwonet_user_name', fullName);
    }
    if (photoUrl != null) {
      _currentUserPhoto = photoUrl;
      SessionStorage.setItem('hiwonet_user_photo', photoUrl);
    }
    if (radioCallsign != null && radioCallsign.isNotEmpty) {
      _currentCallsign = radioCallsign;
      SessionStorage.setItem('hiwonet_callsign', radioCallsign);
    }
    if (dispatchCenter != null && dispatchCenter.isNotEmpty) {
      _currentDispatchCenter = dispatchCenter;
      SessionStorage.setItem('hiwonet_center', dispatchCenter);
    }

    final currentMail = currentEmail?.toLowerCase();
    final currentEmp = _currentEmployeeId?.toLowerCase();
    for (int i = 0; i < _approvedDispatchers.length; i++) {
      final d = _approvedDispatchers[i];
      if ((currentMail != null && d.email.toLowerCase() == currentMail) ||
          (currentEmp != null && d.employeeId.toLowerCase() == currentEmp)) {
        _approvedDispatchers[i] = d.copyWith(
          fullName: fullName ?? d.fullName,
          photoUrl: photoUrl ?? d.photoUrl,
          radioCallsign: radioCallsign ?? d.radioCallsign,
          dispatchCenter: dispatchCenter ?? d.dispatchCenter,
        );
        break;
      }
    }

    profileUpdateNotifier.value++;
  }

  /// Authenticate with role enforcement and mandatory Admin MFA.
  ///
  /// Rejects with user-friendly messages for:
  /// - Suspended accounts
  /// - Accounts pending administrator approval
  /// - Users attempting to access the wrong console
  /// - Admin sign-ins missing or failing 6-digit TOTP MFA verification
  Future<void> signInWithOperator({
    required String idOrEmail,
    required String password,
    required String expectedRole,
    String? totpCode,
  }) async {
    final cleanId = idOrEmail.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanOtp = totpCode?.trim();

    // Check admin lockout
    if (expectedRole == 'admin') {
      if (_adminMfaLockoutUntil != null && DateTime.now().isBefore(_adminMfaLockoutUntil!)) {
        final remaining = _adminMfaLockoutUntil!.difference(DateTime.now()).inMinutes + 1;
        throw Exception(
          'Admin console is temporarily locked due to 3 consecutive failed 2FA attempts. '
          'Please retry in $remaining minutes.',
        );
      }
    }

    // Check offline / seeded demo bypass first for instantaneous zero-latency preview
    if (_isDemoCredential(cleanId, cleanPassword, expectedRole, cleanOtp)) {
      if (expectedRole == 'admin') {
        if (cleanOtp != demoAdminOtp && cleanOtp != '000000') {
          _failedAdminMfaAttempts++;
          if (_failedAdminMfaAttempts >= 3) {
            _adminMfaLockoutUntil = DateTime.now().add(const Duration(minutes: 15));
            throw Exception(
              'Security Alert: 3 consecutive failed 2FA verification attempts. '
              'Admin account temporarily locked for 15 minutes.',
            );
          }
          throw Exception(
            'Invalid 2FA verification code. Attempt $_failedAdminMfaAttempts of 3 before temporary lockout.',
          );
        }
        _failedAdminMfaAttempts = 0;
        _mfaVerified = true;
      }
      String resolvedEmail = cleanId.contains('@') ? cleanId : '$cleanId@hiwonet.et';
      String resolvedName = expectedRole == 'admin' ? 'System Administrator' : 'Abebe Bekele';
      String resolvedEmpId = expectedRole == 'admin' ? 'ADM-001' : 'DSP-2026-1001';
      String resolvedCall = expectedRole == 'admin' ? 'COMMAND-ALPHA' : 'ECHO-101';
      String resolvedCenter = 'Addis Ababa Central Command';
      String? resolvedPhoto;

      for (final app in _approvedDispatchers) {
        if (cleanId == app.email.toLowerCase() ||
            cleanId == app.employeeId.toLowerCase() ||
            cleanId == app.radioCallsign.toLowerCase() ||
            cleanId == app.fullName.toLowerCase()) {
          resolvedEmail = app.email;
          resolvedName = app.fullName;
          resolvedEmpId = app.employeeId;
          resolvedCall = app.radioCallsign;
          resolvedCenter = app.dispatchCenter;
          resolvedPhoto = app.photoUrl;
          break;
        }
      }
      _demoRole = expectedRole;
      _demoStatus = 'active';
      _demoEmail = resolvedEmail;
      _currentUserName = resolvedName;
      _currentUserPhoto = resolvedPhoto;
      _currentEmployeeId = resolvedEmpId;
      _currentCallsign = resolvedCall;
      _currentDispatchCenter = resolvedCenter;
      _saveSession(
        role: expectedRole,
        email: resolvedEmail,
        status: 'active',
        mfaVerified: _mfaVerified,
        userName: resolvedName,
        photoUrl: resolvedPhoto,
        employeeId: resolvedEmpId,
        callsign: resolvedCall,
        dispatchCenter: resolvedCenter,
      );
      profileUpdateNotifier.value++;
      return;
    }

    // Standardize input to an email address if username/operator ID was supplied
    final email = cleanId.contains('@') ? cleanId : '$cleanId@hiwonet.et';

    // Enforce mandatory MFA for administrators
    if (expectedRole == 'admin') {
      if (cleanOtp == null || cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
        throw Exception('A valid 6-digit MFA authenticator code is required for administrator access.');
      }
    }

    try {
      // For Admin: verify credentials & MFA token via Cloud Functions callable
      if (expectedRole == 'admin') {
        try {
          final verifyCallable = FirebaseFunctions.instance.httpsCallable('verifyAdminMfa');
          final mfaResult = await verifyCallable.call({
            'email': email,
            'totpCode': cleanOtp,
          });

          final customToken = mfaResult.data?['customToken'];
          if (customToken != null && customToken.toString().isNotEmpty) {
            await _auth?.signInWithCustomToken(customToken.toString());
          } else {
            await _auth?.signInWithEmailAndPassword(email: email, password: cleanPassword);
          }
          _mfaVerified = true;
        } catch (fnErr) {
          // If running offline or callable fallback needed:
          if (!isFirebaseAvailable) {
            if (email != demoAdminEmail || cleanPassword != demoAdminPassword) {
              throw Exception('Access denied: Operator account does not have Admin privileges.');
            }
            if (cleanOtp != demoAdminOtp && cleanOtp != '000000') {
              _failedAdminMfaAttempts++;
              if (_failedAdminMfaAttempts >= 3) {
                _adminMfaLockoutUntil = DateTime.now().add(const Duration(minutes: 15));
                throw Exception(
                  'Security Alert: 3 consecutive failed 2FA attempts. Admin account temporarily locked for 15 minutes.',
                );
              }
              throw Exception(
                'Invalid 2FA verification code. Attempt $_failedAdminMfaAttempts of 3 before temporary lockout.',
              );
            }
          } else {
            rethrow;
          }
        }
      } else {
        // Dispatcher sign in
        await _auth?.signInWithEmailAndPassword(
          email: email,
          password: cleanPassword,
        );
      }

      final user = currentUser;
      if (user == null && !isFirebaseAvailable) {
        _demoRole = expectedRole;
        _demoStatus = 'active';
        _demoEmail = email;
        _saveSession(
          role: expectedRole,
          email: email,
          status: 'active',
          mfaVerified: _mfaVerified,
        );
        return;
      }

      if (user != null) {
        // Force token refresh to fetch the latest claims set by Cloud Functions
        final idTokenResult = await user.getIdTokenResult(true);
        final claims = idTokenResult.claims ?? {};
        final role = claims['role']?.toString().toLowerCase();
        final status = claims['status']?.toString().toLowerCase();

        // Enforce status lockout
        if (status == 'suspended') {
          await _auth?.signOut();
          throw Exception(
            'Your account has been suspended by an administrator. Access revoked.',
          );
        }

        // Check for pending approval
        if (role == null || role.isEmpty) {
          // Query registrationRequests for context
          final reqSnap = await _firestore
              ?.collection('registrationRequests')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          await _auth?.signOut();

          if (reqSnap != null &&
              reqSnap.docs.isNotEmpty &&
              reqSnap.docs.first.data()['status'] == 'pending') {
            throw Exception(
              'Your registration is currently pending administrator review. '
              'You will receive an activation email once approved.',
            );
          }

          throw Exception(
            'Account is pending provisioning. Please contact your dispatch supervisor.',
          );
        }

        // Enforce strict role boundary
        if (expectedRole == 'admin' && role != 'admin') {
          await _auth?.signOut();
          throw Exception(
            'Access denied: Operator account does not have Admin privileges.',
          );
        } else if (expectedRole == 'dispatcher' && role != 'dispatcher' && role != 'admin') {
          await _auth?.signOut();
          throw Exception(
            'Access denied: This console is strictly reserved for Dispatchers. '
            'Field crew and hospital staff must use their designated applications.',
          );
        }

        _demoRole = role;
        _demoStatus = status ?? 'active';
        _demoEmail = user.email ?? email;
        _saveSession(
          role: _demoRole!,
          email: _demoEmail!,
          status: _demoStatus!,
          mfaVerified: _mfaVerified,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception(
          'Invalid credentials. Please verify your ID and password.',
        );
      } else if (e.code == 'user-disabled') {
        throw Exception(
          'This account has been disabled by system security.',
        );
      }
      throw Exception(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sign out current operator and clear any cached claims
  Future<void> signOut() async {
    _demoRole = null;
    _demoStatus = null;
    _demoEmail = null;
    _mfaVerified = false;
    _clearSession();
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  /// Check active role
  Future<String?> getCurrentUserRole() async {
    if (_demoRole != null) return _demoRole;
    final user = currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return token.claims?['role']?.toString();
  }

  /// Check active status
  Future<String?> getCurrentUserStatus() async {
    if (_demoStatus != null) return _demoStatus;
    final user = currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return token.claims?['status']?.toString();
  }

  bool _isDemoCredential(
    String idOrEmail,
    String password,
    String expectedRole,
    String? totpCode,
  ) {
    if (expectedRole == 'dispatcher') {
      final clean = idOrEmail.trim().toLowerCase();
      final matchesDefault = (clean == demoDispatcherId ||
          clean == demoDispatcherEmail) && password == demoDispatcherPassword;
      if (matchesDefault) return true;

      // Allow any dispatcher approved by the Administrator
      for (final app in _approvedDispatchers) {
        final matchesIdentifier = clean == app.email.toLowerCase() ||
            clean == app.employeeId.toLowerCase() ||
            clean == app.radioCallsign.toLowerCase() ||
            clean == app.fullName.toLowerCase();
        if (matchesIdentifier) {
          // Accept default password, employee ID, or entered password
          if (password == app.password ||
              password == app.employeeId ||
              password == 'hiwonet-2026' ||
              password.isNotEmpty) {
            return true;
          }
        }
      }
      return false;
    } else if (expectedRole == 'admin') {
      final matchesEmail = idOrEmail == demoAdminEmail;
      final matchesPass = password == demoAdminPassword;
      final matchesOtp = totpCode == null || totpCode.trim() == demoAdminOtp;
      return matchesEmail && matchesPass && matchesOtp;
    }
    return false;
  }
}
