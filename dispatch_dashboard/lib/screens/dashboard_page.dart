import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/fleet_models.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_rail.dart';
import '../widgets/live_map_canvas.dart';
import '../widgets/status_badge.dart';
import '../widgets/dispatcher_account_dialog.dart';
import '../widgets/dispatcher_avatar.dart';
import '../services/auth_service.dart';

/// Screen 4 — Dispatcher Workstation Console.
///
/// Features:
/// - Real-time Animated & Interactive Live Map with route simulation and beacon
/// - Fully responsive layout adapting smoothly between mobile, tablet, and wide desktop
/// - Interactive tab switching: Live Map, Emergency Requests, Analytics, and Fleet
/// - Scrollable containers with zero overflow issues on any screen size
/// - Real-time search & priority filtering for fleet and incoming calls
import '../services/fleet_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _railIndex = 0;
  final List<int> _tabHistory = [0];
  String _priorityFilter = 'All';
  String _neighborhoodFilter = 'All';
  final _searchCtl = TextEditingController();
  String? _dispatchedUnitId;
  String? _selectedIncidentId;

  late final List<IncomingRequest> _fallbackRequests = List.from(DemoFleetData.incoming);

  void _onSelectTab(int i) {
    if (_railIndex != i) {
      setState(() {
        _tabHistory.add(i);
        _railIndex = i;
      });
    }
  }

  void _handleBack() {
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _railIndex = _tabHistory.last;
      });
    } else if (_railIndex != 0) {
      setState(() {
        _railIndex = 0;
      });
    } else if (AuthService.instance.isAdmin) {
      context.go('/admin');
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        return StreamBuilder<List<FleetUnit>>(
          stream: FleetRepository.instance.streamAmbulances(),
          builder: (context, unitsSnapshot) {
        final rawUnits = unitsSnapshot.data ?? DemoFleetData.units;
        final query = _searchCtl.text.trim().toLowerCase();

        final units = rawUnits.where((u) {
          final matchesQuery = query.isEmpty ||
              u.label.toLowerCase().contains(query) ||
              u.id.toLowerCase().contains(query);
          return matchesQuery;
        }).toList();

        final available = rawUnits.where((u) => u.status == UnitStatus.available).length;
        final active = rawUnits
            .where((u) => u.status == UnitStatus.enRoute || u.status == UnitStatus.onScene)
            .length;

        return StreamBuilder<List<IncomingRequest>>(
          stream: FleetRepository.instance.streamIncidents(),
          builder: (context, requestsSnapshot) {
            final allRequests = (requestsSnapshot.hasData && requestsSnapshot.data!.isNotEmpty)
                ? requestsSnapshot.data!
                : _fallbackRequests;

            // Multi-criteria filter: Priority, Neighborhood name & text search
            final requests = allRequests.where((r) {
              final matchesPriority = _priorityFilter == 'All' ||
                  (_priorityFilter == 'P1' && r.severity.contains('1')) ||
                  (_priorityFilter == 'P2' && r.severity.contains('2'));

              final matchesNeighborhood = _neighborhoodFilter == 'All' ||
                  r.address.toLowerCase().contains(_neighborhoodFilter.toLowerCase());

              final matchesQuery = query.isEmpty ||
                  r.address.toLowerCase().contains(query) ||
                  r.callerName.toLowerCase().contains(query) ||
                  r.id.toLowerCase().contains(query);

              return matchesPriority && matchesNeighborhood && matchesQuery;
            }).toList();

            final activeRequests = requests.isNotEmpty ? requests : allRequests;
            final selectedRequest = activeRequests.firstWhere(
              (r) => r.id == _selectedIncidentId,
              orElse: () => activeRequests.first,
            );

            // Compute dynamic route suggestion for selected incident
            final route = RouteSuggestion(
              unitId: selectedRequest.suggestedUnitId ?? (units.isNotEmpty ? units.first.id : 'AMB-4712'),
              destinationLabel: '${selectedRequest.address} (${selectedRequest.callerName})',
              distanceKm: selectedRequest.distanceKm ?? 2.4,
              eta: Duration(minutes: selectedRequest.etaMinutes ?? 6),
              trafficCondition: 'Corridor cleared • Light traffic',
            );

            return Scaffold(
              backgroundColor: AppColors.canvas,
              body: Row(
                children: [
                  IconRail(
                    selectedIndex: _railIndex,
                    onSelect: _onSelectTab,
                    items: [
                      const RailItem(Icons.map_outlined, 'Live Map'),
                      RailItem(Icons.inbox_outlined, 'Requests', badge: '${requests.length}'),
                      const RailItem(Icons.bar_chart_outlined, 'Analytics', badge: 'Live'),
                      RailItem(Icons.local_shipping_outlined, 'Fleet', badge: '${rawUnits.length}'),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(
                          available: available,
                          active: active,
                          totalUnits: rawUnits.length,
                          totalRequests: allRequests.length,
                          etaLabel: '${route.eta.inMinutes}m',
                          searchCtl: _searchCtl,
                          priority: _priorityFilter,
                          onPriorityChanged: (v) => setState(() => _priorityFilter = v),
                          neighborhood: _neighborhoodFilter,
                          onNeighborhoodChanged: (v) => setState(() => _neighborhoodFilter = v),
                          railIndex: _railIndex,
                          canGoBack: _railIndex != 0 || _tabHistory.length > 1 || AuthService.instance.isAdmin,
                          onBack: _handleBack,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildCurrentView(units, route, selectedRequest, active, requests),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
      },
    );
  }

  Widget _buildCurrentView(
    List<FleetUnit> units,
    RouteSuggestion route,
    IncomingRequest request,
    int activeCount,
    List<IncomingRequest> liveRequests,
  ) {
    switch (_railIndex) {
      case 1:
        return _buildRequestsView(liveRequests);
      case 2:
        return _buildAnalyticsView();
      case 3:
        return _buildFleetView(units);
      case 0:
      default:
        return _buildLiveMapView(units, route, request, activeCount);
    }
  }

  Widget _buildLiveMapView(
    List<FleetUnit> units,
    RouteSuggestion route,
    IncomingRequest request,
    int activeCount,
  ) {
    return LayoutBuilder(builder: (context, c) {
      final stacked = c.maxWidth < 920;

      final mapStack = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: LiveMapCanvas(
              routeDistanceLabel: '${route.distanceKm.toStringAsFixed(1)} km',
              routeEtaLabel: '${route.eta.inMinutes}m ETA',
              isDispatched: _dispatchedUnitId == route.unitId,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _IncomingCard(request: request),
          ),
        ],
      );

      final sidePanelContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SuggestedRoutingCard(
            route: route,
            dispatched: _dispatchedUnitId == route.unitId,
            onDispatch: () async {
              try {
                await FleetRepository.instance.dispatchAmbulance(
                  ambulanceId: route.unitId,
                  destination: route.destinationLabel,
                  incidentId: request.id,
                );
                if (!mounted) return;
                setState(() => _dispatchedUnitId = route.unitId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E293B),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${route.unitId} successfully dispatched to ${route.destinationLabel}. Synced with Firebase!',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                final msg = e.toString().replaceFirst('Exception: ', '');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.brandRed,
                    content: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg.contains('already dispatched')
                                ? 'Unit ${route.unitId} was already dispatched by another operator.'
                                : 'Dispatch notice: $msg',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _FleetPanel(
            units: units,
            dispatchedUnitId: _dispatchedUnitId,
          ),
        ],
      );

      if (stacked) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 380, child: mapStack),
              const SizedBox(height: 16),
              sidePanelContent,
            ],
          ),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: mapStack),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: sidePanelContent,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRequestsView(List<IncomingRequest> liveRequests) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_outlined, color: AppColors.brandRed, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Incoming Emergency Requests Queue',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink),
                ),
                const Spacer(),
                Text(
                  '${liveRequests.length} Live from Firebase',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: liveRequests.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = liveRequests[i];
                  final isP1 = r.severity.contains('1');
                  final minutesAgo = DateTime.now().difference(r.receivedAt).inMinutes;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isP1
                                ? AppColors.brandRed.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isP1 ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: isP1 ? AppColors.brandRed : AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.id,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isP1 ? AppColors.brandRed : AppColors.warning,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.severity,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${minutesAgo}m ago',
                                    style: TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.callerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.address,
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandRed,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedIncidentId = r.id;
                              _railIndex = 0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E293B),
                                content: Row(
                                  children: [
                                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Loaded incident ${r.id} (${r.address}) into live routing map.',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation, size: 14),
                          label: const Text('Route on Map', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 750;
            final cards = [
              _metricCard(
                '7.8 min',
                'Avg Emergency Response Time',
                Icons.timer_outlined,
                '-1.2m vs last week',
                AppColors.success,
              ),
              _metricCard(
                '94.2%',
                'Fleet Readiness Rate',
                Icons.local_shipping_outlined,
                '45 / 48 in service',
                const Color(0xFF2563EB),
              ),
              _metricCard(
                '38 sec',
                'Call Triage to Dispatch Time',
                Icons.bolt_outlined,
                'Target: < 45s',
                AppColors.success,
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          }),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dispatch volume by hour',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 580,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _barCol('08:00', 0.45, '9 calls'),
                            _barCol('09:00', 0.70, '14 calls'),
                            _barCol('10:00', 0.85, '17 calls'),
                            _barCol('11:00', 1.00, '20 calls (Peak)'),
                            _barCol('12:00', 0.65, '13 calls'),
                            _barCol('13:00', 0.50, '10 calls'),
                            _barCol('14:00', 0.80, '16 calls'),
                            _barCol('15:00', 0.60, '12 calls'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String val,
    String title,
    IconData icon,
    String badge,
    Color color,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              val,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(heightPct * 20).toInt()}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Container(
                height: 120 * heightPct,
                decoration: BoxDecoration(
                  color: heightPct == 1.0 ? AppColors.brandRed : const Color(0xFF2563EB),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetView(List<FleetUnit> units) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.brandRed, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fleet Vehicle Roster & GPS Telemetry',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${units.length} Units Online',
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<Map<String, Map<String, dynamic>>>(
                stream: FleetRepository.instance.streamLivePositions(),
                builder: (context, posSnap) {
                  final positions = posSnap.data ?? {};
                  return ListView.separated(
                    itemCount: units.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = units[i];
                      final live = positions[u.id];
                      final liveLat = (live?['lat'] is num) ? (live!['lat'] as num).toDouble() : u.lat;
                      final liveLng = (live?['lng'] is num) ? (live!['lng'] as num).toDouble() : u.lng;
                      final speed = (live?['speed'] is num)
                          ? '${(live!['speed'] as num).toInt()} km/h'
                          : (u.status == UnitStatus.enRoute ? '48 km/h' : '0 km/h (Stationary)');
                      final destination = live?['destination']?.toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: u.status == UnitStatus.enRoute
                                  ? AppColors.brandRed.withValues(alpha: 0.12)
                                  : AppColors.chipBg,
                              child: Icon(
                                Icons.airport_shuttle,
                                size: 18,
                                color: u.status == UnitStatus.enRoute
                                    ? AppColors.brandRed
                                    : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        u.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${u.id})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                      if (destination != null && destination.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '➔ $destination',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.brandRed,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'GPS: ${liveLat.toStringAsFixed(4)}°N, ${liveLng.toStringAsFixed(4)}°E   |   Speed: $speed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: u.status),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setState(() {
                                  _railIndex = 0;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1E293B),
                                    content: Text('Tracking ${u.label} (${u.id}) on Live Map'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.my_location, size: 14),
                              label: const Text('Track', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int available;
  final int active;
  final int totalUnits;
  final int totalRequests;
  final String etaLabel;
  final TextEditingController searchCtl;
  final String priority;
  final ValueChanged<String> onPriorityChanged;
  final String neighborhood;
  final ValueChanged<String> onNeighborhoodChanged;
  final int railIndex;
  final bool canGoBack;
  final VoidCallback onBack;

  const _TopBar({
    required this.available,
    required this.active,
    this.totalUnits = 8,
    this.totalRequests = 12,
    required this.etaLabel,
    required this.searchCtl,
    required this.priority,
    required this.onPriorityChanged,
    required this.neighborhood,
    required this.onNeighborhoodChanged,
    required this.railIndex,
    required this.canGoBack,
    required this.onBack,
  });

  String get _title {
    switch (railIndex) {
      case 1:
        return 'Dispatch HQ — Emergency Requests';
      case 2:
        return 'Dispatch HQ — Live Analytics & System Trends';
      case 3:
        return 'Dispatch HQ — Fleet Management';
      case 0:
      default:
        return 'Dispatch HQ — Live Routing Map';
    }
  }

  IconData get _pageIcon {
    switch (railIndex) {
      case 1:
        return Icons.inbox_outlined;
      case 2:
        return Icons.bar_chart_outlined;
      case 3:
        return Icons.local_shipping_outlined;
      case 0:
      default:
        return Icons.map_outlined;
    }
  }

  static const List<String> _neighborhoodList = [
    'All',
    // 11 Official Sub-cities
    'Addis Ketema',
    'Akaky Kaliti',
    'Arada',
    'Bole',
    'Gulele',
    'Kirkos',
    'Kolfe Keranyo',
    'Lemi Kura',
    'Lideta',
    'Nifas Silk-Lafto',
    'Yeka',
    // Major Addis Ababa Neighborhoods & Districts
    '22 Mazoria',
    '4 Kilo',
    '6 Kilo',
    'Abado',
    'ALERT / Zenebework',
    'Arat Kilo',
    'Asco',
    'Autobis Tera',
    'Aware',
    'Ayat',
    'Balcha',
    'Bambis',
    'Beherawi',
    'Bella',
    'Bole Arabsa',
    'Bole Bulbula',
    'Bole Medhanialem',
    'Bole Michael',
    'CMC',
    'Cherkos',
    'Dej Zewdu Aba Koran',
    'Dembel',
    'Derartu Tulu Square',
    'Dil Ber',
    'Ferensay Legasion',
    'Figa',
    'Galla Sefer',
    'Gerji',
    'Gerji Roba',
    'German Square',
    'Gofa Camp',
    'Gofa Gebriel',
    'Gofa Sefer',
    'Gotera',
    'Habte Giyorgis',
    'Haya Hulet',
    'Imperial',
    'Jomo',
    'Kadisco',
    'Kaliti',
    'Kazanchis',
    'Kera',
    'Kotebe',
    'Lagar (Legehar)',
    'Lambaret',
    'Lebu',
    'Megenagna',
    'Mekanissa',
    'Menelik Square',
    'Merkato',
    'Meskel Flower',
    'Meskel Square',
    'Mexico',
    'Olympia',
    'Piazza',
    'Popolare',
    'Ras Desta',
    'Rwanda',
    'Sarbet',
    'Saris',
    'Saris Abo',
    'Sefere Selam',
    'Shiromeda',
    'Shola Market',
    'Sidist Kilo',
    'Stadium Area',
    'Summit',
    'Tafo',
    'Teklehaimanot',
    'Tikur Anbessa',
    'Tor Hailoch',
    'Total (Gulele)',
    'Urael',
    'Wingate',
    'Wollo Sefer',
    'Yeka Abado',
    'Yekatit 12 Square',
    'Zenebework',
    'Zewditu Area',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF991B1B), // Command Deep Crimson Red
            Color(0xFFDC2626), // Emergency Vivid Red
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF7F1D1D), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final isNarrow = c.maxWidth < 1120;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Title & Right Actions (Guaranteed No Overflow)
              Row(
                children: [
                  if (canGoBack) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                      tooltip: AuthService.instance.isAdmin && railIndex == 0
                          ? 'Back to Admin Console'
                          : 'Back to Dispatcher Map',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (AuthService.instance.isAdmin) ...[
                    _buildBackToAdminButton(context, compact: true),
                    const SizedBox(width: 6),
                  ],
                  Icon(_pageIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDispatcherBadge(context, compact: true),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const ThemeToggleButton(compact: true, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  _buildLogoutButton(context, compact: true),
                ],
              ),
              // Row 2: Page-Specific Controls (Horizontally Scrollable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildPageSpecificWidgets(),
                  ),
                ),
              ),
            ],
          );
        }

        // Wide Desktop (>= 1120px): Single Unified Row
        return Row(
          children: [
            if (canGoBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                tooltip: AuthService.instance.isAdmin && railIndex == 0
                    ? 'Back to Admin Console'
                    : 'Back to Dispatcher Map',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: onBack,
              ),
              const SizedBox(width: 6),
            ],
            if (AuthService.instance.isAdmin) ...[
              _buildBackToAdminButton(context),
              const SizedBox(width: 10),
            ],
            Icon(_pageIcon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildPageSpecificWidgets(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _buildDispatcherBadge(context),
            const SizedBox(width: 10),
            Container(
              height: 22,
              width: 1,
              color: Colors.white.withValues(alpha: 0.30),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const ThemeToggleButton(compact: true, color: Colors.white),
            ),
            const SizedBox(width: 10),
            _buildLogoutButton(context),
          ],
        );
      }),
    );
  }

  /// Builds context-sensitive controls tailored specifically to the active tab page
  List<Widget> _buildPageSpecificWidgets() {
    switch (railIndex) {
      case 1:
        // Emergency Requests tab
        return [
          _metric('$totalRequests', 'Pending Calls'),
          const SizedBox(width: 10),
          _buildSearchField('Search caller, address or ID...', width: 220),
          const SizedBox(width: 8),
          _buildNeighborhoodDropdown(),
          const SizedBox(width: 8),
          _buildPriorityDropdown(),
        ];
      case 2:
        // Live Analytics tab
        return [
          _metric('< 8.0m', 'Target ETA'),
          const SizedBox(width: 10),
          _metric('99.8%', 'Telemetry Online'),
          const SizedBox(width: 10),
          _metric('11 / 11', 'Sub-cities Monitored'),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Live Telemetry Active',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ];
      case 3:
        // Fleet Management tab
        return [
          _metric('$totalUnits', 'Total Ambulances'),
          const SizedBox(width: 10),
          _metric('$available', 'Ready Units'),
          const SizedBox(width: 10),
          _metric('$active', 'En Route'),
          const SizedBox(width: 10),
          _buildSearchField('Search ambulance unit (AMB-4712), station...', width: 280),
        ];
      case 0:
      default:
        // Live Map tab
        return [
          _metric('$available', 'Available'),
          const SizedBox(width: 10),
          _metric('$active', 'Active'),
          const SizedBox(width: 10),
          _metric(etaLabel, 'Avg. ETA'),
          const SizedBox(width: 10),
          _buildSearchField('Search map unit / address...', width: 220),
        ];
    }
  }

  Widget _buildSearchField(String hint, {double width = 220}) {
    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        controller: searchCtl,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 11.5,
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.20),
          prefixIcon: Icon(Icons.search, size: 15, color: Colors.white.withValues(alpha: 0.90)),
          prefixIconConstraints: const BoxConstraints(minWidth: 28),
          suffixIcon: searchCtl.text.isNotEmpty
              ? InkWell(
                  onTap: () => searchCtl.clear(),
                  child: Icon(Icons.close, size: 13, color: Colors.white.withValues(alpha: 0.90)),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 24),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Colors.white, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: neighborhood,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Colors.white),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          items: _neighborhoodList
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      n == 'All' ? 'Area: All' : n,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onNeighborhoodChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: priority,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Colors.white),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          items: const [
            DropdownMenuItem(
              value: 'All',
              child: Text('Priority: All', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'P1',
              child: Text('Priority 1 (Emergency)', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'P2',
              child: Text('Priority 2 (Urgent)', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
          onChanged: (v) {
            if (v != null) onPriorityChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildDispatcherBadge(BuildContext context, {bool compact = false}) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.instance.profileUpdateNotifier,
      builder: (context, _, __) {
        final name = AuthService.instance.currentUserName;
        final photo = AuthService.instance.currentUserPhoto;
        final callsign = AuthService.instance.currentCallsign;

        return Tooltip(
          message: 'Dispatcher Profile: $name ($callsign)\nClick to view account info and change photo',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => DispatcherAccountDialog.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DispatcherAvatar(
                    radius: 13,
                    photoUrl: photo,
                    name: name,
                    showOnlineDot: true,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                  if (!compact && callsign.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        callsign,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 3),
                  Icon(Icons.unfold_more, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, {bool compact = false}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.20),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFFF1E56), size: 22),
                SizedBox(width: 8),
                Text('Confirm Dispatcher Sign Out'),
              ],
            ),
            content: const Text(
              'Are you sure you want to log out of your Dispatcher console? You will need to sign in again to access the live workstation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E56),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Log Out'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await AuthService.instance.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dispatcher logged out successfully.'),
                backgroundColor: Color(0xFF1E293B),
                duration: Duration(seconds: 2),
              ),
            );
            context.go('/login');
          }
        }
      },
      icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
      label: compact
          ? const SizedBox.shrink()
          : const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
            ),
    );
  }

  Widget _buildBackToAdminButton(BuildContext context, {bool compact = false}) {
    if (!AuthService.instance.isAdmin) return const SizedBox.shrink();

    return Tooltip(
      message: 'Return to System Administrator Console',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.3,
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.28),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => context.go('/admin'),
        icon: const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white),
        label: Text(
          compact ? 'Back to Admin' : 'Back to Admin Console',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final IncomingRequest request;
  const _IncomingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: AppColors.brandRed),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brandRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Incoming call',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandRed,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          request.id,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.callerName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.address,
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedRoutingCard extends StatelessWidget {
  final RouteSuggestion route;
  final bool dispatched;
  final VoidCallback onDispatch;

  const _SuggestedRoutingCard({
    required this.route,
    required this.dispatched,
    required this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3.5, color: AppColors.brandRed),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, size: 16, color: AppColors.brandRed),
                        const SizedBox(width: 6),
                        const Text(
                          'Suggested route',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            route.unitId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: AppColors.brandRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      route.destinationLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statChip('${route.distanceKm.toStringAsFixed(1)} km', Icons.straighten),
                        const SizedBox(width: 8),
                        _statChip('${route.eta.inMinutes} min ETA', Icons.schedule),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          route.trafficCondition,
                          style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dispatched ? AppColors.success : AppColors.brandRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: dispatched ? null : onDispatch,
                        icon: Icon(
                          dispatched ? Icons.check_circle : Icons.local_shipping,
                          size: 16,
                        ),
                        label: Text(
                          dispatched ? 'Unit Dispatched' : 'Dispatch Nearest Unit',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.inkSoft),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _FleetPanel extends StatelessWidget {
  final List<FleetUnit> units;
  final String? dispatchedUnitId;

  const _FleetPanel({required this.units, required this.dispatchedUnitId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fleet units',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${units.length} online',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No fleet units match your search.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ),
            ),
          for (final u in units)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: u.status == UnitStatus.available
                          ? AppColors.success
                          : (u.status == UnitStatus.enRoute
                              ? AppColors.brandRed
                              : AppColors.inkSoft),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      u.label,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                  if (u.id == dispatchedUnitId)
                    const StatusBadge(status: UnitStatus.enRoute)
                  else
                    StatusBadge(status: u.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
