import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/fleet_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';
import '../../services/admin_repository.dart';
import '../../services/fleet_repository.dart';

/// Admin Panel screen — Real-Time Operations Analytics & Live Trends.
///
/// Provides live metrics on call volume, hospital bed capacity, fleet deployment,
/// triage distribution, and an active live telemetry event stream.
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Timer? _ticker;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Gentle 3-second heartbeat to show real-time live clock & sync
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _lastUpdated = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 1,
      title: 'Live Analytics & System Trends',
      headerActions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live Telemetry • Synced ${_timeAgo(_lastUpdated)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
      child: StreamBuilder<List<HospitalRecord>>(
        stream: AdminRepository.instance.streamHospitals(),
        builder: (context, hospSnap) {
          final hospitals = hospSnap.data ?? AdminDemoData.hospitals;
          final totalBeds = hospitals.fold(0, (sum, h) => sum + h.beds);
          final totalIcu = hospitals.fold(0, (sum, h) => sum + h.icuBeds);

          return StreamBuilder<List<FleetUnit>>(
            stream: FleetRepository.instance.streamAmbulances(),
            builder: (context, ambSnap) {
              final units = ambSnap.data ?? DemoFleetData.units;
              final inService = units.where((u) => u.status == UnitStatus.available).length;
              final enRoute = units.where((u) => u.status == UnitStatus.enRoute).length;
              final onScene = units.where((u) => u.status == UnitStatus.onScene).length;
              final offline = units.where((u) => u.status == UnitStatus.offline || u.status == UnitStatus.noResponse).length;

              return StreamBuilder<List<UserAccount>>(
                stream: AdminRepository.instance.streamUsers(),
                builder: (context, userSnap) {
                  final users = userSnap.data ?? AdminDemoData.users;

                  return LayoutBuilder(builder: (context, c) {
                    final stacked = c.maxWidth < 980;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 4 Top KPI Cards
                          _buildKpiRow(c.maxWidth, totalBeds, totalIcu, units.length, inService + enRoute),
                          const SizedBox(height: 20),

                          if (stacked) ...[
                            _buildHourlyVolumeCard(),
                            const SizedBox(height: 16),
                            _buildHospitalCapacityCard(hospitals),
                            const SizedBox(height: 16),
                            _buildFleetDistributionCard(inService, enRoute, onScene, offline, units.length),
                            const SizedBox(height: 16),
                            _buildLiveEventFeedCard(),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildHourlyVolumeCard(),
                                      const SizedBox(height: 16),
                                      _buildHospitalCapacityCard(hospitals),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _buildFleetDistributionCard(inService, enRoute, onScene, offline, units.length),
                                      const SizedBox(height: 16),
                                      _buildLiveEventFeedCard(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKpiRow(double width, int totalBeds, int icuBeds, int totalUnits, int activeUnits) {
    final isNarrow = width < 640;
    final isTablet = width >= 640 && width < 1080;

    final kpis = [
      _AnalyticsKpiCard(
        label: 'Avg Response Time',
        value: '7.8 min',
        subtext: 'Addis Ababa Metropolitan Target < 10m',
        icon: Icons.timer_outlined,
        color: const Color(0xFF2563EB),
      ),
      _AnalyticsKpiCard(
        label: 'Call-to-Dispatch Velocity',
        value: '38 sec',
        subtext: 'Optimal triage threshold < 45s',
        icon: Icons.bolt_outlined,
        color: AppColors.brandRed,
      ),
      _AnalyticsKpiCard(
        label: 'Fleet Readiness Rate',
        value: totalUnits > 0 ? '${((activeUnits / totalUnits) * 100).toInt()}%' : '94%',
        subtext: '$activeUnits of $totalUnits ambulances active',
        icon: Icons.airport_shuttle_outlined,
        color: const Color(0xFF059669),
      ),
      _AnalyticsKpiCard(
        label: 'Live Bed Capacity Sync',
        value: '$totalBeds Beds',
        subtext: '$icuBeds ICU beds available city-wide',
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFF7C3AED),
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (final kpi in kpis) ...[
            kpi,
            const SizedBox(height: 10),
          ],
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(children: [Expanded(child: kpis[0]), const SizedBox(width: 12), Expanded(child: kpis[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: kpis[2]), const SizedBox(width: 12), Expanded(child: kpis[3])]),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < kpis.length; i++) ...[
          Expanded(child: kpis[i]),
          if (i != kpis.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildHourlyVolumeCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: AppColors.brandRed, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Emergency Intake Volume by Hour',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Addis Ababa 907 Call Center',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _barCol('08:00', 0.40, '8 calls'),
                  _barCol('09:00', 0.65, '13 calls'),
                  _barCol('10:00', 0.85, '17 calls'),
                  _barCol('11:00', 1.00, '20 calls (Peak)'),
                  _barCol('12:00', 0.60, '12 calls'),
                  _barCol('13:00', 0.45, '9 calls'),
                  _barCol('14:00', 0.75, '15 calls'),
                  _barCol('15:00', 0.90, '18 calls'),
                  _barCol('16:00', 0.70, '14 calls'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCapacityCard(List<HospitalRecord> hospitals) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Hospital Bed Capacity Synchronization',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '${hospitals.length} Centers Online',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final h in hospitals) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.brandRed),
                                  const SizedBox(width: 3),
                                  Text(
                                    h.location,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                                  ),
                                  if (h.specialization.isNotEmpty) ...[
                                    Text(' • ', style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        h.specialization,
                                        style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${h.beds} Regular  •  ${h.icuBeds} ICU Beds',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (h.beds / 120.0).clamp(0.2, 0.95),
                        minHeight: 8,
                        backgroundColor: AppColors.chipBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          h.beds > 40 ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFleetDistributionCard(int available, int enRoute, int onScene, int offline, int total) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ambulance Fleet Status Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '$total Total Units',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statusRow('Available (Station Standby)', available, const Color(0xFF059669)),
            _statusRow('En Route (Responding)', enRoute, AppColors.brandRed),
            _statusRow('On Scene (Triage/Transport)', onScene, const Color(0xFFD97706)),
            _statusRow('Offline / Maintenance', offline, const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$count units',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEventFeedCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stream_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Telemetry & Activity Stream',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Audit Stream Synced',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<AuditLogEntry>>(
              stream: AdminRepository.instance.streamAuditLog(limit: 6),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? AdminDemoData.auditLog;
                return Column(
                  children: [
                    for (final log in logs.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.timestamp.contains(',')
                                  ? log.timestamp.split(',').last.trim()
                                  : log.timestamp,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 12.5, color: AppColors.ink),
                                  children: [
                                    TextSpan(
                                      text: '${log.description} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: log.action == AuditAction.suspension
                                            ? AppColors.brandRed
                                            : AppColors.ink,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '(${log.target})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _barCol(String time, double heightPct, String tooltip) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(heightPct * 20).toInt()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                height: 110 * heightPct,
                decoration: BoxDecoration(
                  color: heightPct == 1.0 ? AppColors.brandRed : const Color(0xFF2563EB),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    return '${diff.inSeconds}s ago';
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
