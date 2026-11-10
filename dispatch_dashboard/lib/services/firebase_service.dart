import '../models/fleet_models.dart';
import '../models/admin_models.dart';
import 'fleet_repository.dart';
import 'admin_repository.dart';

/// Legacy facade pointing to modern [FleetRepository] and [AdminRepository].
/// Preserved for backwards compatibility.
class FirebaseService {
  static Stream<List<FleetUnit>> streamFleetUnits() =>
      FleetRepository.instance.streamAmbulances();

  static Stream<List<IncomingRequest>> streamEmergencyRequests() =>
      FleetRepository.instance.streamIncidents();

  static Stream<List<HospitalRecord>> streamHospitals() =>
      FleetRepository.instance.streamHospitals();

  static Stream<List<UserAccount>> streamUsers() =>
      AdminRepository.instance.streamUsers();

  static Future<void> dispatchUnit({
    required String unitId,
    required String destination,
  }) =>
      FleetRepository.instance.dispatchAmbulance(
        ambulanceId: unitId,
        destination: destination,
      );

  static Future<void> seedIfEmpty() async {
    // No-op or delegates to repositories
  }
}
