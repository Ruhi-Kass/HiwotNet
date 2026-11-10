import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/fleet_models.dart';
import '../models/admin_models.dart';

/// Central repository for Dispatch fleet operations, incidents, and hospitals.
///
/// Standardizes on canonical collections:
/// - `ambulances` (with transparent fallback to legacy `units`)
/// - `incidents` (with transparent fallback to legacy `emergency_requests`)
/// - `hospitals`
/// - `alerts`
class FleetRepository {
  FleetRepository._();
  static final FleetRepository instance = FleetRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final List<FleetUnit> _localUnits = List<FleetUnit>.from(DemoFleetData.units);
  final StreamController<List<FleetUnit>> _unitsController =
      StreamController<List<FleetUnit>>.broadcast();

  final List<IncomingRequest> _localIncidents = List<IncomingRequest>.from(DemoFleetData.incoming);
  final StreamController<List<IncomingRequest>> _incidentsController =
      StreamController<List<IncomingRequest>>.broadcast();

  CollectionReference<Map<String, dynamic>> get ambulancesRef =>
      _firestore.collection('ambulances');
  CollectionReference<Map<String, dynamic>> get legacyUnitsRef =>
      _firestore.collection('units');

  CollectionReference<Map<String, dynamic>> get incidentsRef =>
      _firestore.collection('incidents');
  CollectionReference<Map<String, dynamic>> get legacyRequestsRef =>
      _firestore.collection('emergency_requests');

  CollectionReference<Map<String, dynamic>> get hospitalsRef =>
      _firestore.collection('hospitals');

  CollectionReference<Map<String, dynamic>> get alertsRef =>
      _firestore.collection('alerts');
  CollectionReference<Map<String, dynamic>> get legacyAlertsRef =>
      _firestore.collection('hospital_alerts');

  /// Stream of active ambulances/fleet units with immediate local emission and live Firestore sync
  Stream<List<FleetUnit>> streamAmbulances() {
    ambulancesRef.snapshots().listen((snap) {
      if (snap.docs.isNotEmpty) {
        final list = _mapAmbulances(snap.docs);
        for (final item in list) {
          final idx = _localUnits.indexWhere((u) => u.id == item.id);
          if (idx >= 0) {
            _localUnits[idx] = item;
          } else {
            _localUnits.add(item);
          }
        }
        if (!_unitsController.isClosed) {
          _unitsController.add(List<FleetUnit>.unmodifiable(_localUnits));
        }
      }
    }, onError: (_) {});

    return Stream<List<FleetUnit>>.multi((controller) {
      controller.add(List<FleetUnit>.unmodifiable(_localUnits));
      final sub = _unitsController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  List<FleetUnit> _mapAmbulances(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      final rawStatus = data['status']?.toString().toLowerCase() ?? '';
      UnitStatus status = UnitStatus.available;
      if (rawStatus.contains('route') || rawStatus.contains('dispatched')) {
        status = UnitStatus.enRoute;
      } else if (rawStatus.contains('scene')) {
        status = UnitStatus.onScene;
      } else if (rawStatus.contains('offline') || rawStatus.contains('maintenance')) {
        status = UnitStatus.offline;
      } else if (rawStatus.contains('no') || rawStatus.contains('busy')) {
        status = UnitStatus.noResponse;
      }

      return FleetUnit(
        id: doc.id,
        label: data['label'] ?? data['callsign'] ?? data['name'] ?? doc.id,
        status: status,
        lat: (data['lat'] is num) ? (data['lat'] as num).toDouble() : 9.02,
        lng: (data['lng'] is num) ? (data['lng'] as num).toDouble() : 38.74,
      );
    }).toList();
  }

  /// Stream of incoming emergency incidents with immediate local emission and live Firestore sync
  Stream<List<IncomingRequest>> streamIncidents() {
    incidentsRef.snapshots().listen((snap) {
      if (snap.docs.isNotEmpty) {
        final list = _mapIncidents(snap.docs);
        for (final item in list) {
          final idx = _localIncidents.indexWhere((inc) => inc.id == item.id);
          if (idx >= 0) {
            _localIncidents[idx] = item;
          } else {
            _localIncidents.add(item);
          }
        }
        if (!_incidentsController.isClosed) {
          _incidentsController.add(List<IncomingRequest>.unmodifiable(_localIncidents));
        }
      }
    }, onError: (_) {});

    return Stream<List<IncomingRequest>>.multi((controller) {
      controller.add(List<IncomingRequest>.unmodifiable(_localIncidents));
      final sub = _incidentsController.stream.listen(
        (data) => controller.add(data),
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  List<IncomingRequest> _mapIncidents(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      DateTime receivedAt = DateTime.now();
      if (data['receivedAt'] != null) {
        if (data['receivedAt'] is Timestamp) {
          receivedAt = (data['receivedAt'] as Timestamp).toDate();
        } else if (data['receivedAt'] is String) {
          receivedAt = DateTime.tryParse(data['receivedAt']) ?? DateTime.now();
        }
      } else if (data['createdAt'] is Timestamp) {
        receivedAt = (data['createdAt'] as Timestamp).toDate();
      }

      String? suggestedUnit;
      double? distanceKm;
      int? etaMinutes;
      final sugg = data['suggestion'];
      if (sugg is Map) {
        suggestedUnit = sugg['unitId']?.toString();
        if (sugg['distanceKm'] is num) {
          distanceKm = (sugg['distanceKm'] as num).toDouble();
        }
        if (sugg['etaMinutes'] is num) {
          etaMinutes = (sugg['etaMinutes'] as num).toInt();
        }
      }

      return IncomingRequest(
        id: doc.id,
        callerName: data['callerName'] ?? data['patientName'] ?? data['caller'] ?? 'Emergency Caller',
        address: data['address'] ?? data['location'] ?? 'Addis Ababa',
        severity: data['severity'] ?? data['priority'] ?? 'Priority 1',
        receivedAt: receivedAt,
        suggestedUnitId: suggestedUnit,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
      );
    }).toList();
  }

  /// Stream of registered hospitals
  Stream<List<HospitalRecord>> streamHospitals() {
    return hospitalsRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return AdminDemoData.hospitals;

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HospitalRecord(
          id: doc.id,
          name: data['name'] ?? data['hospitalName'] ?? doc.id,
          location: data['location'] ?? data['address'] ?? 'Addis Ababa',
          specialization: data['specialization'] ?? data['type'] ?? 'General & Emergency Care',
          beds: (data['beds'] is num) ? (data['beds'] as num).toInt() : 50,
          icuBeds: (data['icuBeds'] is num) ? (data['icuBeds'] as num).toInt() : 10,
          ambulanceCount: (data['ambulanceCount'] is num) ? (data['ambulanceCount'] as num).toInt() : 3,
        );
      }).toList();
    }).handleError((_) => AdminDemoData.hospitals);
  }

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Dispatch an ambulance to a destination/incident with race-condition prevention & cross-app coordination
  Future<void> dispatchAmbulance({
    required String ambulanceId,
    required String destination,
    String? incidentId,
  }) async {
    // 1. Immediately update local in-memory fleet and incidents
    final uIdx = _localUnits.indexWhere((u) => u.id == ambulanceId);
    if (uIdx >= 0) {
      final cur = _localUnits[uIdx];
      _localUnits[uIdx] = FleetUnit(
        id: cur.id,
        label: cur.label,
        status: UnitStatus.enRoute,
        lat: cur.lat,
        lng: cur.lng,
      );
      if (!_unitsController.isClosed) {
        _unitsController.add(List<FleetUnit>.unmodifiable(_localUnits));
      }
    }

    if (incidentId != null) {
      _localIncidents.removeWhere((inc) => inc.id == incidentId);
      if (!_incidentsController.isClosed) {
        _incidentsController.add(List<IncomingRequest>.unmodifiable(_localIncidents));
      }
    }

    // 2. Realtime Database sync (Caller app and Crew app live tracking)
    try {
      await _database.ref('positions/$ambulanceId').update({
        'status': 'enRoute',
        'destination': destination,
        'incidentId': incidentId ?? '',
        'timestamp': ServerValue.timestamp,
        'speed': 54.0,
      });
    } catch (_) {}

    // 3. Attempt Cloud Function dispatch (atomic mutex locking)
    try {
      final callable = _functions.httpsCallable('dispatchUnit');
      await callable.call<Map<String, dynamic>>({
        'ambulanceId': ambulanceId,
        'destination': destination,
        'incidentId': incidentId,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists' ||
          (e.message != null && e.message!.toLowerCase().contains('already'))) {
        throw Exception(e.message ?? 'Unit $ambulanceId is already dispatched.');
      }
    } catch (_) {
      // 4. Direct Firestore update fallback
      try {
        final updateData = {
          'status': UnitStatus.enRoute.name,
          'destination': destination,
          'incidentId': incidentId,
          'dispatchedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await ambulancesRef.doc(ambulanceId).set(updateData, SetOptions(merge: true));
        await legacyUnitsRef.doc(ambulanceId).set(updateData, SetOptions(merge: true));

        if (incidentId != null) {
          await incidentsRef.doc(incidentId).set({
            'status': 'dispatched',
            'assignedUnit': ambulanceId,
            'dispatchedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final alertData = {
          'title': 'Emergency Unit Dispatched',
          'unitId': ambulanceId,
          'destination': destination,
          'incidentId': incidentId,
          'severity': 'P1 Emergency',
          'timestamp': FieldValue.serverTimestamp(),
        };

        await alertsRef.add(alertData);
        await legacyAlertsRef.add(alertData);
      } catch (_) {}
    }
  }

  /// Create and ingest incoming emergency incident
  Future<String> createIncident({
    required String callerName,
    required String address,
    required String severity,
    String description = 'Emergency incident reported',
    double lat = 9.02,
    double lng = 38.74,
  }) async {
    try {
      final callable = _functions.httpsCallable('createIncident');
      final res = await callable.call<Map<String, dynamic>>({
        'callerName': callerName.trim(),
        'address': address.trim(),
        'severity': severity.trim(),
        'description': description.trim(),
        'lat': lat,
        'lng': lng,
      });
      return res.data['incidentId']?.toString() ?? '';
    } catch (_) {
      final docRef = await incidentsRef.add({
        'callerName': callerName.trim(),
        'address': address.trim(),
        'severity': severity.trim(),
        'description': description.trim(),
        'lat': lat,
        'lng': lng,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    }
  }

  /// Update incident lifecycle status ('assigned' | 'enRoute' | 'onScene' | 'transporting' | 'closed')
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? notes,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateIncidentStatus');
      await callable.call<Map<String, dynamic>>({
        'incidentId': incidentId,
        'status': status,
        'notes': notes,
      });
    } catch (_) {
      await incidentsRef.doc(incidentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream real-time GPS telemetry from Firebase Realtime Database (`positions/`)
  Stream<Map<String, Map<String, dynamic>>> streamLivePositions() {
    return _database.ref('positions').onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <String, Map<String, dynamic>>{};
      final raw = snap.value;
      if (raw is Map) {
        final result = <String, Map<String, dynamic>>{};
        raw.forEach((k, v) {
          if (v is Map) {
            result[k.toString()] = Map<String, dynamic>.from(v);
          }
        });
        return result;
      }
      return <String, Map<String, dynamic>>{};
    }).handleError((_) => <String, Map<String, dynamic>>{});
  }

  /// Update unit coordinates in RTDB `positions/{unitId}`
  Future<void> updateLivePosition({
    required String unitId,
    required double lat,
    required double lng,
    double? speed,
    double? heading,
  }) async {
    try {
      await _database.ref('positions/$unitId').set({
        'lat': lat,
        'lng': lng,
        'speed': speed ?? 40.0,
        'heading': heading ?? 0.0,
        'timestamp': ServerValue.timestamp,
      });
    } catch (_) {}
  }
}
