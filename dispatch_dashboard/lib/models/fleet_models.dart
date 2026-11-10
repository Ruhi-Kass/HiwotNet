/// Mock domain models for the Live Map & Routing screen. In the real app
/// these would come from the dispatch API / websocket feed; here they give
/// the UI real shapes to render so the screen isn't hard-coded strings.
library;

enum UnitStatus { available, enRoute, onScene, noResponse, offline }

class FleetUnit {
  final String id;
  final String label;
  final UnitStatus status;
  final double lat;
  final double lng;

  const FleetUnit({
    required this.id,
    required this.label,
    required this.status,
    required this.lat,
    required this.lng,
  });
}

class IncomingRequest {
  final String id;
  final String callerName;
  final String address;
  final String severity; // e.g. "Priority 1"
  final DateTime receivedAt;
  final String? suggestedUnitId;
  final double? distanceKm;
  final int? etaMinutes;

  const IncomingRequest({
    required this.id,
    required this.callerName,
    required this.address,
    required this.severity,
    required this.receivedAt,
    this.suggestedUnitId,
    this.distanceKm,
    this.etaMinutes,
  });
}

class RouteSuggestion {
  final String unitId;
  final String destinationLabel;
  final double distanceKm;
  final Duration eta;
  final String trafficCondition;

  const RouteSuggestion({
    required this.unitId,
    required this.destinationLabel,
    required this.distanceKm,
    required this.eta,
    required this.trafficCondition,
  });
}

/// Demo dataset — stands in for a live GPS feed.
class DemoFleetData {
  DemoFleetData._();

  static const units = <FleetUnit>[
    FleetUnit(
        id: 'AMB-1',
        label: 'AMB-1',
        status: UnitStatus.available,
        lat: 9.03,
        lng: 38.74),
    FleetUnit(
        id: 'AMB-2',
        label: 'AMB-2',
        status: UnitStatus.noResponse,
        lat: 9.01,
        lng: 38.76),
    FleetUnit(
        id: 'AMB-3',
        label: 'AMB-3',
        status: UnitStatus.enRoute,
        lat: 9.02,
        lng: 38.72),
    FleetUnit(
        id: 'AMB-4',
        label: 'AMB-4',
        status: UnitStatus.available,
        lat: 9.04,
        lng: 38.78),
  ];

  static final incoming = <IncomingRequest>[
    IncomingRequest(
      id: 'REQ-1042',
      callerName: 'Tewodros Assefa (Caller)',
      address: 'Bole Medhanialem, Zone 3, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      suggestedUnitId: 'AMB-4712',
      distanceKm: 2.4,
      etaMinutes: 6,
    ),
    IncomingRequest(
      id: 'REQ-1043',
      callerName: 'Sara Mengistu (Caller)',
      address: 'Kazanchis Business Corridor, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      suggestedUnitId: 'AMB-4708',
      distanceKm: 3.1,
      etaMinutes: 8,
    ),
    IncomingRequest(
      id: 'REQ-1044',
      callerName: 'Amanuel Tadesse (Caller)',
      address: 'Piazza St. George Square, Addis Ababa',
      severity: 'Priority 2',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      suggestedUnitId: 'AMB-4705',
      distanceKm: 1.8,
      etaMinutes: 5,
    ),
    IncomingRequest(
      id: 'REQ-1045',
      callerName: 'Fatima Ahmed (Caller)',
      address: 'Merkato Trade Quarter, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      suggestedUnitId: 'AMB-4719',
      distanceKm: 4.2,
      etaMinutes: 10,
    ),
    IncomingRequest(
      id: 'REQ-1046',
      callerName: 'Dawit Solomon (Caller)',
      address: 'Sarbet International Zone, Addis Ababa',
      severity: 'Priority 2',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      suggestedUnitId: 'AMB-4722',
      distanceKm: 3.5,
      etaMinutes: 9,
    ),
    IncomingRequest(
      id: 'REQ-1047',
      callerName: 'Almaz Worku (Caller)',
      address: 'Kolfe Keranyo, near ALERT Hospital, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 18)),
      suggestedUnitId: 'AMB-4710',
      distanceKm: 2.9,
      etaMinutes: 7,
    ),
    IncomingRequest(
      id: 'REQ-1048',
      callerName: 'Kidus Haile (Caller)',
      address: 'Lideta, Mexico Square, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 22)),
      suggestedUnitId: 'AMB-4714',
      distanceKm: 1.5,
      etaMinutes: 4,
    ),
    IncomingRequest(
      id: 'REQ-1049',
      callerName: 'Selamawit Tsegaye (Caller)',
      address: 'Gulele, Shiromeda Market, Addis Ababa',
      severity: 'Priority 2',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 26)),
      suggestedUnitId: 'AMB-4706',
      distanceKm: 3.8,
      etaMinutes: 9,
    ),
    IncomingRequest(
      id: 'REQ-1050',
      callerName: 'Biruk Tesfaye (Caller)',
      address: 'Gerji, CMC Road, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      suggestedUnitId: 'AMB-4713',
      distanceKm: 4.0,
      etaMinutes: 11,
    ),
    IncomingRequest(
      id: 'REQ-1051',
      callerName: 'Hanna Desta (Caller)',
      address: 'Mekanissa, German Square, Nifas Silk-Lafto, Addis Ababa',
      severity: 'Priority 2',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 35)),
      suggestedUnitId: 'AMB-4718',
      distanceKm: 3.2,
      etaMinutes: 8,
    ),
    IncomingRequest(
      id: 'REQ-1052',
      callerName: 'Mulugeta Bekele (Caller)',
      address: 'Kirkos, Meskel Flower & Olympia, Addis Ababa',
      severity: 'Priority 1',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      suggestedUnitId: 'AMB-4711',
      distanceKm: 2.1,
      etaMinutes: 5,
    ),
    IncomingRequest(
      id: 'REQ-1053',
      callerName: 'Genet Alemu (Caller)',
      address: 'Ayat, Derartu Tulu Square, Lemi Kura, Addis Ababa',
      severity: 'Priority 2',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      suggestedUnitId: 'AMB-4720',
      distanceKm: 5.1,
      etaMinutes: 12,
    ),
  ];

  static const suggestedRoute = RouteSuggestion(
    unitId: 'AMB-3',
    destinationLabel: 'Smith & Jones — collision, 2 injured',
    distanceKm: 1.8,
    eta: Duration(minutes: 7),
    trafficCondition: 'Light traffic',
  );
}
