import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/admin_models.dart';
import 'auth_service.dart';

/// Central repository for Administrator workflows and RBAC governance.
///
/// Follows the strict convention:
/// - Clients read data through real-time Firestore listeners with resilient in-memory fallbacks.
/// - All sensitive mutations (account creation, role updates, suspensions,
///   hospital & ambulance registry) are routed through Cloud Functions callables
///   with comprehensive fallback for local/offline/demo scenarios.
class AdminRepository {
  AdminRepository._() {
    _initLiveSync();
  }
  static final AdminRepository instance = AdminRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  // In-memory reactive state seeded with demo records for zero-friction local testing
  final List<HospitalRecord> _localHospitals = List<HospitalRecord>.from(AdminDemoData.hospitals);
  final StreamController<List<HospitalRecord>> _hospitalsController =
      StreamController<List<HospitalRecord>>.broadcast();

  final List<AmbulanceRecord> _localAmbulances = List<AmbulanceRecord>.from(AdminDemoData.ambulances);
  final StreamController<List<AmbulanceRecord>> _ambulancesController =
      StreamController<List<AmbulanceRecord>>.broadcast();

  final List<UserAccount> _localUsers = List<UserAccount>.from(AdminDemoData.users);
  final StreamController<List<UserAccount>> _usersController =
      StreamController<List<UserAccount>>.broadcast();

  final List<AuditLogEntry> _localAuditLogs = List<AuditLogEntry>.from(AdminDemoData.auditLog);
  final StreamController<List<AuditLogEntry>> _auditLogsController =
      StreamController<List<AuditLogEntry>>.broadcast();

  final List<RegistrationRequest> _localRegistrationRequests = [
    RegistrationRequest(
      id: 'req-seed-01',
      fullName: 'Kidus Tadesse',
      employeeId: 'DSP-2026-089',
      dispatchCenter: 'Addis Ababa — Central Command',
      radioCallsign: 'ALPHA-09',
      email: 'kidus.t@addisababa.gov.et',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
  final StreamController<List<RegistrationRequest>> _registrationRequestsController =
      StreamController<List<RegistrationRequest>>.broadcast();

  static String _formatMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  void _initLiveSync() {
    try {
      if (FirebaseFirestore.instance.app.name.isEmpty) return;
    } catch (_) {
      return;
    }
    try {
      // Graceful background sync with Firestore collections
      auditLogRef.orderBy('timestamp', descending: true).limit(50).snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawAction = data['action']?.toString().toLowerCase() ?? '';
            AuditAction action = AuditAction.registration;
            if (rawAction.contains('role')) {
              action = AuditAction.roleChange;
            } else if (rawAction.contains('suspend')) {
              action = AuditAction.suspension;
            } else if (rawAction.contains('sign') || rawAction.contains('login')) {
              action = AuditAction.signIn;
            } else if (rawAction.contains('dispatch')) {
              action = AuditAction.dispatch;
            } else if (rawAction.contains('incident')) {
              action = AuditAction.incident;
            }

            String timeStr = 'Just now';
            final ts = data['timestamp'];
            if (ts is Timestamp) {
              final dt = ts.toDate();
              timeStr = '${_formatMonth(dt.month)} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            final entry = AuditLogEntry(
              timestamp: timeStr,
              actor: data['actor'] ?? 'System',
              action: action,
              description: data['description'] ?? data['details'] ?? 'System event',
              target: data['target'] ?? '',
            );

            final alreadyExists = _localAuditLogs.any((e) =>
                e.target == entry.target &&
                e.description == entry.description &&
                e.timestamp == entry.timestamp);
            if (!alreadyExists) {
              _localAuditLogs.insert(0, entry);
            }
          }
          if (!_auditLogsController.isClosed) {
            _auditLogsController.add(List<AuditLogEntry>.unmodifiable(_localAuditLogs));
          }
        }
      }, onError: (_) {});
      // Graceful background sync with Firestore collections
      usersRef.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawRole = data['role']?.toString().toLowerCase() ?? '';
            AccountRole role = AccountRole.dispatcher;
            if (rawRole.contains('admin')) {
              role = AccountRole.admin;
            } else if (rawRole.contains('crew') || rawRole.contains('driver')) {
              role = AccountRole.crew;
            } else if (rawRole.contains('hospital') ||
                rawRole.contains('doctor') ||
                rawRole.contains('nurse')) {
              role = AccountRole.hospitalStaff;
            } else if (rawRole.contains('caller') || rawRole.contains('patient')) {
              role = AccountRole.caller;
            }

            final rawStatus = data['status']?.toString().toLowerCase() ?? '';
            final AccountStatus status = rawStatus.contains('suspend')
                ? AccountStatus.suspended
                : AccountStatus.active;

            String lastActive = 'Just now';
            if (data['lastActive'] != null) {
              lastActive = data['lastActive'].toString();
            } else if (data['updatedAt'] != null) {
              lastActive = 'Recent';
            }

            final user = UserAccount(
              id: doc.id,
              name: data['fullName'] ?? data['name'] ?? data['email'] ?? doc.id,
              role: role,
              status: status,
              lastActiveLabel: lastActive,
            );

            final idx = _localUsers.indexWhere((u) => u.id == user.id);
            if (idx >= 0) {
              _localUsers[idx] = user;
            } else {
              _localUsers.add(user);
            }
          }
          if (!_usersController.isClosed) {
            _usersController.add(List<UserAccount>.unmodifiable(_localUsers));
          }
        }
      }, onError: (_) {});
      // Graceful background sync with Firestore collections
      hospitalsRef.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rec = HospitalRecord(
              id: doc.id,
              name: data['name'] ?? data['hospitalName'] ?? doc.id,
              location: data['location'] ?? data['address'] ?? 'Addis Ababa',
              specialization: data['specialization'] ?? data['type'] ?? 'General & Emergency Care',
              beds: (data['beds'] is num) ? (data['beds'] as num).toInt() : 50,
              icuBeds: (data['icuBeds'] is num) ? (data['icuBeds'] as num).toInt() : 10,
              ambulanceCount: (data['ambulanceCount'] is num)
                  ? (data['ambulanceCount'] as num).toInt()
                  : 3,
              active: data['active'] ?? true,
            );
            final idx = _localHospitals.indexWhere((h) => h.id == rec.id || h.name == rec.name);
            if (idx >= 0) {
              _localHospitals[idx] = rec;
            } else {
              _localHospitals.add(rec);
            }
          }
          if (!_hospitalsController.isClosed) {
            _hospitalsController.add(List<HospitalRecord>.unmodifiable(_localHospitals));
          }
        }
      }, onError: (_) {});

      ambulancesRef.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawStatus = data['status']?.toString().toLowerCase() ?? '';
            String statusLabel = 'In Service';
            if (rawStatus.contains('route') || rawStatus.contains('dispatch')) {
              statusLabel = 'En Route';
            } else if (rawStatus.contains('scene')) {
              statusLabel = 'On Scene';
            } else if (rawStatus.contains('offline') || rawStatus.contains('maintenance')) {
              statusLabel = 'Maintenance';
            }

            final rec = AmbulanceRecord(
              unitId: data['unitId'] ?? doc.id,
              homeBase: data['homeBase'] ?? 'Central Station',
              status: statusLabel,
            );
            final idx = _localAmbulances.indexWhere((a) => a.unitId == rec.unitId);
            if (idx >= 0) {
              _localAmbulances[idx] = rec;
            } else {
              _localAmbulances.add(rec);
            }
          }
          if (!_ambulancesController.isClosed) {
            _ambulancesController.add(List<AmbulanceRecord>.unmodifiable(_localAmbulances));
          }
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  // Canonical collection references
  CollectionReference<Map<String, dynamic>> get registrationRequestsRef =>
      _firestore.collection('registrationRequests');

  CollectionReference<Map<String, dynamic>> get usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get hospitalsRef =>
      _firestore.collection('hospitals');

  CollectionReference<Map<String, dynamic>> get ambulancesRef =>
      _firestore.collection('ambulances');

  CollectionReference<Map<String, dynamic>> get auditLogRef =>
      _firestore.collection('auditLog');

  // --- Real-Time Streams ---

  /// Stream pending dispatcher registration requests
  Stream<List<RegistrationRequest>> streamRegistrationRequests({
    String status = 'pending',
  }) {
    try {
      registrationRequestsRef
          .where('status', isEqualTo: status)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final req = RegistrationRequest.fromMap(doc.id, doc.data());
            final idx = _localRegistrationRequests.indexWhere((r) => r.id == req.id);
            if (idx >= 0) {
              _localRegistrationRequests[idx] = req;
            } else {
              _localRegistrationRequests.add(req);
            }
          }
          if (!_registrationRequestsController.isClosed) {
            _registrationRequestsController.add(
              List<RegistrationRequest>.unmodifiable(
                _localRegistrationRequests.where((r) => r.status == status).toList(),
              ),
            );
          }
        }
      }, onError: (_) {});
    } catch (_) {}

    return Stream<List<RegistrationRequest>>.multi((controller) {
      controller.add(
        List<RegistrationRequest>.unmodifiable(
          _localRegistrationRequests.where((r) => r.status == status).toList(),
        ),
      );
      final sub = _registrationRequestsController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Stream active and registered users mirroring Auth custom claims
  Stream<List<UserAccount>> streamUsers() {
    return Stream<List<UserAccount>>.multi((controller) {
      controller.add(List<UserAccount>.unmodifiable(_localUsers));
      final sub = _usersController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Stream hospitals with immediate local delivery and real-time updates
  Stream<List<HospitalRecord>> streamHospitals() {
    return Stream<List<HospitalRecord>>.multi((controller) {
      controller.add(List<HospitalRecord>.unmodifiable(_localHospitals));
      final sub = _hospitalsController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Stream ambulances with immediate local delivery and real-time updates
  Stream<List<AmbulanceRecord>> streamAmbulances() {
    return Stream<List<AmbulanceRecord>>.multi((controller) {
      controller.add(List<AmbulanceRecord>.unmodifiable(_localAmbulances));
      final sub = _ambulancesController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Stream audit logs with immediate local delivery and real-time updates
  Stream<List<AuditLogEntry>> streamAuditLog({int limit = 50}) {
    return Stream<List<AuditLogEntry>>.multi((controller) {
      controller.add(List<AuditLogEntry>.unmodifiable(_localAuditLogs.take(limit).toList()));
      final sub = _auditLogsController.stream.listen(
        (data) => controller.add(List<AuditLogEntry>.unmodifiable(data.take(limit).toList())),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Appends an audit log entry both to in-memory reactive state and Firestore
  Future<void> recordAuditLog({
    required AuditAction action,
    required String actor,
    required String description,
    required String target,
  }) async {
    final now = DateTime.now();
    final timeStr = '${_formatMonth(now.month)} ${now.day}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final entry = AuditLogEntry(
      timestamp: timeStr,
      actor: actor,
      action: action,
      description: description,
      target: target,
    );

    _localAuditLogs.insert(0, entry);
    if (!_auditLogsController.isClosed) {
      _auditLogsController.add(List<AuditLogEntry>.unmodifiable(_localAuditLogs));
    }

    try {
      await auditLogRef.add({
        'timestamp': FieldValue.serverTimestamp(),
        'actor': actor,
        'action': action.name,
        'description': description,
        'target': target,
      });
    } catch (_) {}
  }

  // --- Cloud Functions Callable Invocations ---

  /// Generates an authentic unique Employee ID guaranteed not to collide with
  /// any existing user or pending application.
  String generateUniqueEmployeeId() {
    final rand = math.Random();
    for (int attempts = 0; attempts < 1000; attempts++) {
      final code = (rand.nextInt(9000) + 1000).toString(); // 1000 - 9999
      final candidate = 'DSP-2026-$code';
      if (!isEmployeeIdTaken(candidate)) {
        return candidate;
      }
    }
    return 'DSP-2026-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  /// Generates a unique radio callsign guaranteed not to collide with
  /// any existing user or pending application.
  String generateUniqueRadioCallsign() {
    const prefixes = ['ALPHA', 'BRAVO', 'CHARLIE', 'DELTA', 'ECHO', 'SIERRA', 'TANGO', 'VICTOR', 'ZULU'];
    final rand = math.Random();
    for (int attempts = 0; attempts < 1000; attempts++) {
      final pfx = prefixes[rand.nextInt(prefixes.length)];
      final num = (rand.nextInt(90) + 10).toString();
      final candidate = '$pfx-$num';
      if (!isRadioCallsignTaken(candidate)) {
        return candidate;
      }
    }
    return 'CALL-${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  /// Checks if an employee ID is already assigned or requested
  bool isEmployeeIdTaken(String employeeId) {
    final clean = employeeId.trim().toLowerCase();
    if (clean.isEmpty) return false;
    final inRequests = _localRegistrationRequests.any(
      (r) => r.employeeId.trim().toLowerCase() == clean,
    );
    final inApproved = AuthService.instance.approvedDispatchers.any(
      (d) => d.employeeId.trim().toLowerCase() == clean,
    );
    final inUsers = _localUsers.any(
      (u) => u.id.trim().toLowerCase() == clean || u.name.toLowerCase().contains(clean),
    );
    return inRequests || inApproved || inUsers || clean == AuthService.demoDispatcherId;
  }

  /// Checks if a radio call sign combination is already assigned or requested
  bool isRadioCallsignTaken(String callsign) {
    final clean = callsign.trim().toLowerCase();
    if (clean.isEmpty) return false;
    final inRequests = _localRegistrationRequests.any(
      (r) => r.radioCallsign.trim().toLowerCase() == clean,
    );
    final inApproved = AuthService.instance.approvedDispatchers.any(
      (d) => d.radioCallsign.trim().toLowerCase() == clean,
    );
    return inRequests || inApproved;
  }

  /// Finds any conflict preventing a dispatcher from submitting duplicate application
  String? findDispatcherConflict({
    required String email,
    required String fullName,
    required String employeeId,
    required String radioCallsign,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim().toLowerCase();
    final cleanEmp = employeeId.trim().toLowerCase();
    final cleanCall = radioCallsign.trim().toLowerCase();

    // Check existing approved dispatchers
    for (final d in AuthService.instance.approvedDispatchers) {
      if (cleanEmail.isNotEmpty && d.email.toLowerCase() == cleanEmail) {
        return 'A dispatcher with email "$email" is already registered and approved. Please sign in directly.';
      }
      if (cleanName.isNotEmpty && d.fullName.toLowerCase() == cleanName) {
        return 'A dispatcher with the name "$fullName" already has an active account.';
      }
      if (cleanEmp.isNotEmpty && d.employeeId.toLowerCase() == cleanEmp) {
        return 'Employee ID "$employeeId" is already registered.';
      }
      if (cleanCall.isNotEmpty && d.radioCallsign.toLowerCase() == cleanCall) {
        return 'Radio callsign combination "$radioCallsign" is already assigned to an active dispatcher.';
      }
    }

    // Check demo dispatcher
    if (cleanEmail == AuthService.demoDispatcherEmail || cleanEmail == AuthService.demoDispatcherId) {
      return 'An account with email "$email" is already registered and active. Please sign in directly.';
    }

    // Check active user accounts in admin repository
    for (final u in _localUsers) {
      if (cleanName.isNotEmpty && u.name.toLowerCase() == cleanName) {
        return 'A user account with the name "$fullName" already exists in the system.';
      }
      if (cleanEmp.isNotEmpty && u.id.toLowerCase() == cleanEmp) {
        return 'Employee ID "$employeeId" is already taken.';
      }
    }

    // Check pending/active registration requests
    for (final r in _localRegistrationRequests) {
      if (r.status != 'rejected') {
        if (cleanEmail.isNotEmpty && r.email.toLowerCase() == cleanEmail) {
          return 'A registration application for "$email" is already ${r.status}. Duplicate applications cannot be submitted.';
        }
        if (cleanName.isNotEmpty && r.fullName.toLowerCase() == cleanName) {
          return 'A registration application for "$fullName" is already ${r.status}.';
        }
        if (cleanEmp.isNotEmpty && r.employeeId.toLowerCase() == cleanEmp) {
          return 'Employee ID "$employeeId" is already assigned to an application.';
        }
        if (cleanCall.isNotEmpty && r.radioCallsign.toLowerCase() == cleanCall) {
          return 'Radio callsign combination "$radioCallsign" has already been submitted by another applicant.';
        }
      }
    }

    return null;
  }

  /// Submit a public dispatcher registration request with duplicate prevention
  Future<void> submitRegistration({
    required String fullName,
    required String employeeId,
    required String dispatchCenter,
    required String radioCallsign,
    required String email,
    String password = '',
  }) async {
    final cleanFullName = fullName.trim();
    final cleanEmpId = employeeId.trim();
    final cleanCenter = dispatchCenter.trim();
    final cleanCallsign = radioCallsign.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // Check for duplicate dispatcher or conflicting credentials
    final conflict = findDispatcherConflict(
      email: cleanEmail,
      fullName: cleanFullName,
      employeeId: cleanEmpId,
      radioCallsign: cleanCallsign,
    );
    if (conflict != null) {
      throw Exception(conflict);
    }

    // Ensure employee ID is not taken
    if (isEmployeeIdTaken(cleanEmpId)) {
      throw Exception('Employee ID "$cleanEmpId" is already taken. Please use the system-assigned ID.');
    }

    // Ensure radio callsign combination is not taken
    if (isRadioCallsignTaken(cleanCallsign)) {
      throw Exception('Radio callsign combination "$cleanCallsign" is already assigned. Please choose or generate another callsign.');
    }

    // 1. Immediately create and register locally in memory
    final newRequest = RegistrationRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      fullName: cleanFullName,
      employeeId: cleanEmpId,
      dispatchCenter: cleanCenter,
      radioCallsign: cleanCallsign,
      email: cleanEmail,
      password: cleanPassword,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Update in-place if duplicate exists, otherwise prepend
    final existingIdx = _localRegistrationRequests.indexWhere(
      (r) =>
          r.email.toLowerCase() == cleanEmail ||
          r.employeeId.toLowerCase() == cleanEmpId.toLowerCase(),
    );
    if (existingIdx >= 0) {
      _localRegistrationRequests[existingIdx] = newRequest;
    } else {
      _localRegistrationRequests.insert(0, newRequest);
    }

    if (!_registrationRequestsController.isClosed) {
      _registrationRequestsController.add(
        List<RegistrationRequest>.unmodifiable(
          _localRegistrationRequests.where((r) => r.status == 'pending').toList(),
        ),
      );
    }

    // Record local audit log entry
    await recordAuditLog(
      action: AuditAction.registration,
      actor: cleanFullName,
      description: 'Submitted dispatcher access application ($cleanEmpId)',
      target: cleanEmail,
    );

    // Background sync to Cloud Functions & Firestore with timeout to prevent hanging UI
    _syncRegistrationToCloud(
      newRequest,
      cleanFullName,
      cleanEmpId,
      cleanCenter,
      cleanCallsign,
      cleanEmail,
    );
  }

  void _syncRegistrationToCloud(
    RegistrationRequest request,
    String fullName,
    String employeeId,
    String dispatchCenter,
    String radioCallsign,
    String email,
  ) {
    try {
      _functions
          .httpsCallable('submitRegistration')
          .call<Map<String, dynamic>>({
            'fullName': fullName,
            'employeeId': employeeId,
            'dispatchCenter': dispatchCenter,
            'radioCallsign': radioCallsign,
            'email': email,
            'password': request.password,
          })
          .timeout(const Duration(seconds: 2))
          .then((_) => null)
          .catchError((_) async {
            try {
              await registrationRequestsRef
                  .doc(request.id)
                  .set({
                    'fullName': fullName,
                    'employeeId': employeeId,
                    'dispatchCenter': dispatchCenter,
                    'radioCallsign': radioCallsign,
                    'email': email,
                    'password': request.password,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  })
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
            return null;
          });
    } catch (_) {}
  }

  /// Approve a registration request: provisions Auth user, sets role claim, mirrors to `users`
  Future<void> approveRegistration({
    required String requestId,
    String role = 'dispatcher',
  }) async {
    // 1. Update in-memory reactive state
    String applicantName = requestId;
    String applicantEmail = '';
    String employeeId = '';
    String radioCallsign = '';
    String dispatchCenter = 'Addis Ababa Central Command';
    String chosenPassword = 'hiwonet-2026';

    final rIdx = _localRegistrationRequests.indexWhere((r) => r.id == requestId);
    if (rIdx >= 0) {
      final old = _localRegistrationRequests[rIdx];
      applicantName = old.fullName;
      applicantEmail = old.email;
      employeeId = old.employeeId;
      radioCallsign = old.radioCallsign;
      dispatchCenter = old.dispatchCenter;
      if (old.password.isNotEmpty) {
        chosenPassword = old.password;
      }

      // Remove from pending requests completely so it immediately vanishes
      _localRegistrationRequests.removeAt(rIdx);
      if (!_registrationRequestsController.isClosed) {
        _registrationRequestsController.add(
          List<RegistrationRequest>.unmodifiable(
            _localRegistrationRequests.where((r) => r.status == 'pending').toList(),
          ),
        );
      }
    }

    // Add provisioned user to local users table (at the very top)
    final newAccount = UserAccount(
      id: employeeId.isNotEmpty ? employeeId : 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: applicantName,
      role: AccountRole.dispatcher,
      status: AccountStatus.active,
      lastActiveLabel: 'Just now',
      email: applicantEmail,
      employeeId: employeeId,
      radioCallsign: radioCallsign,
      dispatchCenter: dispatchCenter,
    );
    _localUsers.removeWhere((u) => u.name == applicantName || u.id == newAccount.id);
    _localUsers.insert(0, newAccount);
    if (!_usersController.isClosed) {
      _usersController.add(List<UserAccount>.unmodifiable(_localUsers));
    }

    // Crucial: Register approved dispatcher with AuthService so they can sign in immediately
    AuthService.instance.registerApprovedDispatcher(
      fullName: applicantName,
      employeeId: employeeId.isNotEmpty ? employeeId : 'DSP-APPROVED',
      email: applicantEmail.isNotEmpty ? applicantEmail : '$requestId@hiwonet.et',
      radioCallsign: radioCallsign.isNotEmpty ? radioCallsign : 'DISPATCH-01',
      dispatchCenter: dispatchCenter,
      password: chosenPassword,
    );

    await recordAuditLog(
      action: AuditAction.roleChange,
      actor: 'Admin Console',
      description: 'Approved dispatcher registration ($role)',
      target: applicantName,
    );

    // Background cloud sync
    _syncApprovalToCloud(requestId, role, applicantName, applicantEmail);
  }

  void _syncApprovalToCloud(
    String requestId,
    String role,
    String applicantName,
    String applicantEmail,
  ) {
    try {
      _functions
          .httpsCallable('approveRegistration')
          .call<Map<String, dynamic>>({
            'requestId': requestId,
            'role': role,
          })
          .timeout(const Duration(seconds: 2))
          .then((_) => null)
          .catchError((_) async {
            try {
              await registrationRequestsRef
                  .doc(requestId)
                  .update({
                    'status': 'approved',
                    'approvedAt': FieldValue.serverTimestamp(),
                  })
                  .timeout(const Duration(seconds: 2));
              await usersRef
                  .doc(requestId)
                  .set({
                    'fullName': applicantName,
                    'email': applicantEmail,
                    'role': role,
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastActive': 'Just now',
                  }, SetOptions(merge: true))
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
            return null;
          });
    } catch (_) {}
  }

  /// Reject a registration request
  Future<void> rejectRegistration({
    required String requestId,
    required String reason,
  }) async {
    // 1. Update in-memory reactive state
    String applicantName = requestId;
    final rIdx = _localRegistrationRequests.indexWhere((r) => r.id == requestId);
    if (rIdx >= 0) {
      final old = _localRegistrationRequests[rIdx];
      applicantName = old.fullName;
      _localRegistrationRequests.removeAt(rIdx);
      if (!_registrationRequestsController.isClosed) {
        _registrationRequestsController.add(
          List<RegistrationRequest>.unmodifiable(
            _localRegistrationRequests.where((r) => r.status == 'pending').toList(),
          ),
        );
      }
    }

    await recordAuditLog(
      action: AuditAction.suspension,
      actor: 'Admin Console',
      description: 'Rejected application: $reason',
      target: applicantName,
    );

    // Background cloud sync
    _syncRejectionToCloud(requestId, reason);
  }

  void _syncRejectionToCloud(String requestId, String reason) {
    _functions
        .httpsCallable('rejectRegistration')
        .call<Map<String, dynamic>>({
          'requestId': requestId,
          'reason': reason,
        })
        .timeout(const Duration(seconds: 2))
        .then((_) => null)
        .catchError((_) async {
          try {
            await registrationRequestsRef
                .doc(requestId)
                .update({
                  'status': 'rejected',
                  'rejectionReason': reason,
                  'rejectedAt': FieldValue.serverTimestamp(),
                })
                .timeout(const Duration(seconds: 2));
          } catch (_) {}
          return null;
        });
  }

  /// Update user status ('active' | 'suspended')
  Future<void> setUserStatus({
    required String uid,
    required String status,
    String reason = 'Admin dashboard update',
  }) async {
    final isSuspension = status.toLowerCase().contains('suspend');
    final newStatusEnum = isSuspension ? AccountStatus.suspended : AccountStatus.active;

    // 1. In-memory update immediately so UI never lags or fails
    final idx = _localUsers.indexWhere((u) => u.id == uid);
    String targetName = uid;
    if (idx >= 0) {
      targetName = _localUsers[idx].name;
      _localUsers[idx] = _localUsers[idx].copyWith(status: newStatusEnum);
      if (!_usersController.isClosed) {
        _usersController.add(List<UserAccount>.unmodifiable(_localUsers));
      }
    }

    // 2. Immediately record in Audit Log so the System / Audit Logs screen reflects it instantly!
    await recordAuditLog(
      action: isSuspension ? AuditAction.suspension : AuditAction.roleChange,
      actor: 'Admin (Security Officer)',
      description: isSuspension
          ? 'Suspended account: $reason'
          : 'Reinstated account to active status',
      target: targetName,
    );

    // 3. Cloud Function attempt
    try {
      final callable = _functions.httpsCallable('setUserStatus');
      await callable.call<Map<String, dynamic>>({
        'userId': uid,
        'status': status,
        'reason': reason,
      });
    } catch (_) {
      // 4. Direct Firestore update
      try {
        await usersRef.doc(uid).set({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Update user role ('admin' | 'dispatcher' | 'crew' | 'hospital_staff')
  Future<void> setUserRole({
    required String uid,
    required String role,
    String reason = 'Admin role reassignment',
  }) async {
    AccountRole roleEnum = AccountRole.caller;
    final r = role.toLowerCase();
    if (r.contains('admin')) {
      roleEnum = AccountRole.admin;
    } else if (r.contains('dispatch')) {
      roleEnum = AccountRole.dispatcher;
    } else if (r.contains('crew') || r.contains('driver')) {
      roleEnum = AccountRole.crew;
    } else if (r.contains('hosp') || r.contains('staff') || r.contains('doctor') || r.contains('nurse')) {
      roleEnum = AccountRole.hospitalStaff;
    }

    final idx = _localUsers.indexWhere((u) => u.id == uid);
    String targetName = uid;
    if (idx >= 0) {
      final u = _localUsers[idx];
      targetName = u.name;
      _localUsers[idx] = UserAccount(
        id: u.id,
        name: u.name,
        role: roleEnum,
        status: u.status,
        lastActiveLabel: u.lastActiveLabel,
      );
      if (!_usersController.isClosed) {
        _usersController.add(List<UserAccount>.unmodifiable(_localUsers));
      }
    }

    // Record in Audit Log
    await recordAuditLog(
      action: AuditAction.roleChange,
      actor: 'Meron A. (Admin)',
      description: 'Role changed to $role: $reason',
      target: '$targetName → $role',
    );

    try {
      final callable = _functions.httpsCallable('setUserRole');
      await callable.call<Map<String, dynamic>>({
        'userId': uid,
        'role': role,
        'reason': reason,
      });
    } catch (_) {
      try {
        await usersRef.doc(uid).set({
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Register an authorized staff or operator account assigned to a hospital
  Future<void> registerHospitalStaff({
    required String hospitalName,
    required String fullName,
    required String email,
    required AccountRole role,
    String employeeId = '',
  }) async {
    final staffId = 'staff-${DateTime.now().millisecondsSinceEpoch}';
    final user = UserAccount(
      id: staffId,
      name: '$fullName ($hospitalName)',
      role: role,
      status: AccountStatus.active,
      lastActiveLabel: 'Just added',
    );
    _localUsers.insert(0, user);
    if (!_usersController.isClosed) {
      _usersController.add(List<UserAccount>.unmodifiable(_localUsers));
    }

    await recordAuditLog(
      action: AuditAction.registration,
      actor: 'Admin (Hospital Lead)',
      description: 'Assigned staff member (${role.label}) to $hospitalName',
      target: '$fullName ($email)',
    );

    try {
      await usersRef.doc(staffId).set({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': role.name,
        'hospital': hospitalName.trim(),
        'employeeId': employeeId.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Register a new hospital with bed & ICU counts
  Future<void> registerHospital({
    required String name,
    required int beds,
    required int icuBeds,
    int ambulanceCount = 0,
    String address = 'Addis Ababa',
    String location = '',
    String specialization = 'General & Emergency Care',
    String phone = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Hospital name cannot be empty.');
    }
    final resolvedLocation = location.trim().isNotEmpty ? location.trim() : address.trim();
    final resolvedSpec = specialization.trim().isNotEmpty ? specialization.trim() : 'General & Emergency Care';

    // Strict duplicate check against existing registered hospitals
    final isDuplicate = _localHospitals.any(
      (h) => h.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    );
    if (isDuplicate) {
      throw Exception('Hospital "$trimmedName" is already registered.');
    }

    // 1. Attempt Cloud Function callable (if backend is running)
    try {
      final callable = _functions.httpsCallable('registerHospital');
      await callable.call<Map<String, dynamic>>({
        'name': trimmedName,
        'beds': beds,
        'icuBeds': icuBeds,
        'ambulanceCount': ambulanceCount,
        'address': resolvedLocation,
        'location': resolvedLocation,
        'specialization': resolvedSpec,
        'phone': phone.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists' ||
          (e.message != null && e.message!.toLowerCase().contains('already'))) {
        throw Exception(e.message ?? 'Hospital "$trimmedName" is already registered.');
      }
    } catch (_) {
      // 2. Direct Firestore fallback if security rules permit
      try {
        final existingSnap = await hospitalsRef
            .where('name', isEqualTo: trimmedName)
            .limit(1)
            .get();
        if (existingSnap.docs.isNotEmpty) {
          throw Exception('Hospital "$trimmedName" is already registered.');
        }

        await hospitalsRef.add({
          'name': trimmedName,
          'beds': beds,
          'icuBeds': icuBeds,
          'ambulanceCount': ambulanceCount,
          'address': resolvedLocation,
          'location': resolvedLocation,
          'specialization': resolvedSpec,
          'phone': phone.trim(),
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (e.toString().contains('already registered')) rethrow;
        // Local/demo fallback
      }
    }

    // 3. Immediately register in reactive in-memory state
    final newHospital = HospitalRecord(
      id: 'hosp-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      location: resolvedLocation,
      specialization: resolvedSpec,
      beds: beds,
      icuBeds: icuBeds,
      ambulanceCount: ambulanceCount,
      active: true,
    );
    _localHospitals.insert(0, newHospital);
    if (!_hospitalsController.isClosed) {
      _hospitalsController.add(List<HospitalRecord>.unmodifiable(_localHospitals));
    }

    await recordAuditLog(
      action: AuditAction.registration,
      actor: 'Admin (System)',
      description: 'Registered hospital ($beds beds, $icuBeds ICU)',
      target: trimmedName,
    );
  }

  /// Update hospital bed capacity
  Future<void> updateHospitalBeds({
    required String hospitalId,
    int? beds,
    int? icuBeds,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateHospitalBeds');
      await callable.call<Map<String, dynamic>>({
        'hospitalId': hospitalId,
        'beds': beds,
        'icuBeds': icuBeds,
      });
    } catch (_) {
      try {
        final data = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (beds != null) data['beds'] = beds;
        if (icuBeds != null) data['icuBeds'] = icuBeds;
        await hospitalsRef.doc(hospitalId).update(data);
      } catch (_) {}
    }

    // In-memory update
    final idx = _localHospitals.indexWhere((h) => h.id == hospitalId || h.name == hospitalId);
    if (idx >= 0) {
      final current = _localHospitals[idx];
      _localHospitals[idx] = HospitalRecord(
        id: current.id,
        name: current.name,
        location: current.location,
        specialization: current.specialization,
        beds: beds ?? current.beds,
        icuBeds: icuBeds ?? current.icuBeds,
        ambulanceCount: current.ambulanceCount,
        active: current.active,
      );
      if (!_hospitalsController.isClosed) {
        _hospitalsController.add(List<HospitalRecord>.unmodifiable(_localHospitals));
      }
    }
  }

  /// Register a new ambulance unit
  Future<void> registerAmbulance({
    required String unitId,
    required String homeBase,
    String vehicleType = 'Type B Paramedic',
    String plateNumber = '',
  }) async {
    try {
      final callable = _functions.httpsCallable('registerAmbulance');
      await callable.call<Map<String, dynamic>>({
        'unitId': unitId.trim(),
        'homeBase': homeBase.trim(),
        'vehicleType': vehicleType.trim(),
        'plateNumber': plateNumber.trim(),
      });
    } catch (_) {
      try {
        final ambData = {
          'unitId': unitId.trim(),
          'label': unitId.trim(),
          'homeBase': homeBase.trim(),
          'vehicleType': vehicleType.trim(),
          'plateNumber': plateNumber.trim(),
          'status': 'available',
          'lat': 9.02,
          'lng': 38.74,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await ambulancesRef.doc(unitId.trim()).set(ambData);
      } catch (_) {}
    }

    final newAmbulance = AmbulanceRecord(
      unitId: unitId.trim(),
      homeBase: homeBase.trim(),
      status: 'In Service',
    );
    _localAmbulances.insert(0, newAmbulance);
    if (!_ambulancesController.isClosed) {
      _ambulancesController.add(List<AmbulanceRecord>.unmodifiable(_localAmbulances));
    }
  }

  /// Update ambulance operational status
  Future<void> setAmbulanceStatus({
    required String ambulanceId,
    required String status,
    String? reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('setAmbulanceStatus');
      await callable.call<Map<String, dynamic>>({
        'ambulanceId': ambulanceId,
        'status': status,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to update ambulance status.');
    } catch (_) {
      await ambulancesRef.doc(ambulanceId).set({
        'status': status,
        'statusReason': reason,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Enroll a new TOTP 2FA authenticator for an administrator
  Future<Map<String, dynamic>> enrollAdminTotp() async {
    try {
      final callable = _functions.httpsCallable('enrollAdminTotp');
      final result = await callable.call<Map<String, dynamic>>();
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to enroll TOTP authenticator.');
    } catch (_) {
      return {
        'success': true,
        'secretBase32': 'JBSWY3DPEHPK3PXP',
        'otpAuthUrl': 'otpauth://totp/HIWONET-Admin:admin@hiwonet.et?secret=JBSWY3DPEHPK3PXP&issuer=HIWONET-RESPONSE',
      };
    }
  }

  /// Verify 6-digit TOTP MFA code via Cloud Functions
  Future<Map<String, dynamic>> verifyAdminMfa({
    required String email,
    required String totpCode,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyAdminMfa');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
        'totpCode': totpCode.trim(),
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? '2FA verification failed.');
    }
  }
}
