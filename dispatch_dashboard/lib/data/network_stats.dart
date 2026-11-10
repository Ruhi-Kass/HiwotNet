/// Single source of truth for the handful of network-wide numbers that
/// show up on *both* the public Landing Page and the Admin Dashboard
/// (ambulance count, hospital count, etc.). Keeping them here instead of
/// duplicated literals is what keeps the two dashboards "working well
/// together" instead of silently drifting apart.
class NetworkStats {
  NetworkStats._();

  static const int totalAmbulances = 48;
  static const int totalHospitals = 28;
  static const String avgResponseTime = '6.8m';

  // Admin-side totals (not shown pre-auth, but kept here so they can be
  // cross-checked against the dispatcher-facing numbers above).
  static const int totalUsers = 312;
}
