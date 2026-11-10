import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/fleet_repository.dart';

/// Interactive, animated Live Map canvas for the Dispatcher Console.
///
/// Features:
/// - Continuous real-time animation (pulsing emergency beacon, moving ambulance, flowing route dashes)
/// - Interactive zoom & pan via [InteractiveViewer]
/// - Tap-to-inspect vehicle telemetry popup
/// - Zoom in / Zoom out / Reset controls
/// - Live GPS telemetry status indicator
class LiveMapCanvas extends StatefulWidget {
  final String routeDistanceLabel;
  final String routeEtaLabel;
  final bool isDispatched;

  const LiveMapCanvas({
    super.key,
    required this.routeDistanceLabel,
    required this.routeEtaLabel,
    this.isDispatched = false,
  });

  @override
  State<LiveMapCanvas> createState() => _LiveMapCanvasState();
}

class _MapUnitData {
  final String id;
  final String callsign;
  final String status;
  final Color color;
  final double xRatio;
  final double yRatio;
  final String driver;
  final String speed;
  final String fuel;
  final bool isEmergency;

  const _MapUnitData({
    required this.id,
    required this.callsign,
    required this.status,
    required this.color,
    required this.xRatio,
    required this.yRatio,
    required this.driver,
    required this.speed,
    required this.fuel,
    this.isEmergency = false,
  });
}

class _LiveMapCanvasState extends State<LiveMapCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final TransformationController _transformController = TransformationController();
  StreamSubscription? _posSub;
  Map<String, Map<String, dynamic>> _livePositions = {};
  DateTime _lastTelemetrySync = DateTime.now();

  String get _syncLabel {
    final diff = DateTime.now().difference(_lastTelemetrySync);
    if (diff.inSeconds < 5) return 'just now';
    return '${diff.inSeconds}s ago';
  }

  _MapUnitData? _selectedUnit;

  List<_MapUnitData> get _resolvedUnits {
    if (_livePositions.isEmpty) return _mapUnits;
    return _mapUnits.map((u) {
      if (_livePositions.containsKey(u.id)) {
        final pos = _livePositions[u.id]!;
        final lat = (pos['lat'] is num) ? (pos['lat'] as num).toDouble() : null;
        final lng = (pos['lng'] is num) ? (pos['lng'] as num).toDouble() : null;
        final speed = pos['speed']?.toString();
        if (lat != null && lng != null) {
          // Normalize coordinates across Addis Ababa metropolitan bounding box
          final x = ((lng - 38.70) / 0.10).clamp(0.08, 0.92);
          final y = (1.0 - (lat - 8.98) / 0.08).clamp(0.08, 0.92);
          return _MapUnitData(
            id: u.id,
            callsign: u.callsign,
            status: u.status,
            color: u.color,
            xRatio: x,
            yRatio: y,
            driver: u.driver,
            speed: speed != null ? '$speed km/h (Live GPS)' : u.speed,
            fuel: u.fuel,
            isEmergency: u.isEmergency,
          );
        }
      }
      return u;
    }).toList();
  }

  static final List<_MapUnitData> _mapUnits = [
    _MapUnitData(
      id: 'AMB-4712',
      callsign: 'Medic 12 (Dispatched)',
      status: 'Responding to P1 Emergency',
      color: AppColors.brandRed,
      xRatio: 0.28,
      yRatio: 0.62,
      driver: 'Paramedic Dawit T. & Helen B.',
      speed: '58 km/h',
      fuel: '84%',
      isEmergency: true,
    ),
    _MapUnitData(
      id: 'AMB-4705',
      callsign: 'Squad 05',
      status: 'Available - St. Paul Base',
      color: AppColors.success,
      xRatio: 0.58,
      yRatio: 0.28,
      driver: 'EMT Yohannes & Sara M.',
      speed: '0 km/h (Standby)',
      fuel: '92%',
    ),
    _MapUnitData(
      id: 'AMB-4708',
      callsign: 'Medic 08',
      status: 'En Route to Tikur Anbessa',
      color: AppColors.success,
      xRatio: 0.78,
      yRatio: 0.55,
      driver: 'Paramedic Abebe K.',
      speed: '42 km/h',
      fuel: '76%',
    ),
    _MapUnitData(
      id: 'AMB-4719',
      callsign: 'Transport 19',
      status: 'On Scene - Bole Medhanialem',
      color: AppColors.warning,
      xRatio: 0.15,
      yRatio: 0.30,
      driver: 'EMT Almaz & Kebede',
      speed: '0 km/h',
      fuel: '65%',
    ),
    _MapUnitData(
      id: 'AMB-4722',
      callsign: 'Medic 22',
      status: 'Available - Torhailoch District',
      color: AppColors.ink,
      xRatio: 0.60,
      yRatio: 0.78,
      driver: 'EMT Samuel B.',
      speed: '0 km/h (Patrol)',
      fuel: '89%',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _posSub = FleetRepository.instance.streamLivePositions().listen((positions) {
      if (mounted) {
        setState(() {
          if (positions.isNotEmpty) _livePositions = positions;
          _lastTelemetrySync = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scale(1.25);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scale(0.8);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        children: [
          // Interactive pan & zoom map area
          Container(
            color: AppColors.canvas,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.7,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(120),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return LayoutBuilder(builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onTapUp: (details) {
                        _handleTap(details.localPosition, size);
                      },
                      child: Stack(
                        children: [
                          _OsmTileGrid(size: size),
                          CustomPaint(
                            size: size,
                            painter: _EnhancedMapPainter(
                              animValue: _animController.value,
                              units: _resolvedUnits,
                              selectedUnit: _selectedUnit,
                              isDispatched: widget.isDispatched,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
          ),

          // Route info badge (top-left)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.route, size: 14, color: AppColors.brandRed),
                  const SizedBox(width: 6),
                  Text(
                    widget.routeDistanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 1, height: 12,
                      color: AppColors.border,
                    ),
                  ),
                  Text(
                    widget.routeEtaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // OpenStreetMap live telemetry sync badge (top-right)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OpenStreetMap • Synced $_syncLabel',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),



          // Zoom & Reset controls (bottom-right above incident chip)
          Positioned(
            right: 14,
            bottom: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapControlButton(Icons.add, _zoomIn, 'Zoom In'),
                const SizedBox(height: 4),
                _mapControlButton(Icons.remove, _zoomOut, 'Zoom Out'),
                const SizedBox(height: 4),
                _mapControlButton(Icons.center_focus_strong, _resetZoom, 'Reset View'),
              ],
            ),
          ),

          // Vehicle Telemetry Card Popup when a unit dot is clicked
          if (_selectedUnit != null)
            Positioned(
              left: 14,
              top: 58,
              child: _buildTelemetryPopup(_selectedUnit!),
            ),
        ],
      ),
    );
  }

  void _handleTap(Offset localPos, Size size) {
    _MapUnitData? tapped;
    for (final u in _resolvedUnits) {
      final unitPos = Offset(u.xRatio * size.width, u.yRatio * size.height);
      if ((localPos - unitPos).distance < 24) {
        tapped = u;
        break;
      }
    }
    setState(() {
      _selectedUnit = tapped;
    });
  }

  Widget _mapControlButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }

  Widget _buildTelemetryPopup(_MapUnitData unit) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: unit.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedUnit = null),
                child: Icon(Icons.close, size: 16, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            unit.callsign,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const Divider(height: 16),
          _detailRow(Icons.radio_button_checked, 'Status', unit.status),
          const SizedBox(height: 4),
          _detailRow(Icons.person, 'Crew', unit.driver),
          const SizedBox(height: 4),
          _detailRow(Icons.speed, 'Speed', unit.speed),
          const SizedBox(height: 4),
          _detailRow(Icons.local_gas_station, 'Fuel', unit.fuel),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.inkSoft),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
        ),
        Expanded(
          child: Text(
            val,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EnhancedMapPainter extends CustomPainter {
  final double animValue;
  final List<_MapUnitData> units;
  final _MapUnitData? selectedUnit;
  final bool isDispatched;

  _EnhancedMapPainter({
    required this.animValue,
    required this.units,
    required this.selectedUnit,
    required this.isDispatched,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw district map background features
    _drawDistrictLandmarks(canvas, size);

    // 2. Road network
    _drawRoadNetwork(canvas, size);

    // 3. Suggested & Active Route Line
    final start = Offset(size.width * 0.28, size.height * 0.62);
    final end = Offset(size.width * 0.58, size.height * 0.28);
    _drawAnimatedRoute(canvas, start, end);

    // 4. Moving vehicle along route
    _drawMovingAmbulance(canvas, start, end);

    // 5. Pulsing emergency radar beacon at destination
    _drawEmergencyBeacon(canvas, end);

    // 6. Draw unit dots with subtle pulsing halos
    for (final u in units) {
      final pos = Offset(u.xRatio * size.width, u.yRatio * size.height);
      _drawUnitMarker(canvas, pos, u);
    }
  }

  void _drawDistrictLandmarks(Canvas canvas, Size size) {
    final isDark = AppThemeController.isDark;

    // Soft green park area
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF14291E) : const Color(0xFFDCEAD9)
      ..style = PaintingStyle.fill;
    final parkPath = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.35)
      ..lineTo(size.width * 0.72, size.height * 0.22)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    // Soft water canal / river line
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF162A42) : const Color(0xFFD3E4F4)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.78,
        size.width * 0.9,
        size.height * 0.95,
      );
    canvas.drawPath(riverPath, waterPaint);
  }

  void _drawRoadNetwork(Canvas canvas, Size size) {
    final isDark = AppThemeController.isDark;
    final arterialPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3B4E) : Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.square;

    final secondaryPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF7F8F9)
      ..strokeWidth = 3;

    // Major Arterials
    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.38),
      arterialPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.68),
      arterialPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      arterialPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, 0),
      Offset(size.width * 0.72, size.height),
      arterialPaint,
    );

    // Diagonal ring road
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.15),
      arterialPaint,
    );

    // Secondary grid roads
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), secondaryPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), secondaryPaint);
    }
  }

  void _drawAnimatedRoute(Canvas canvas, Offset a, Offset b) {
    // Outer glow for route
    final glowPaint = Paint()
      ..color = AppColors.brandRed.withValues(alpha: 0.22)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(a, b, glowPaint);

    // Flowing animated dash line
    final total = (b - a).distance;
    final direction = (b - a) / total;
    const dashLength = 8.0;
    const gapLength = 6.0;
    final cycle = dashLength + gapLength;

    final offsetProgress = (animValue * cycle);

    final dashPaint = Paint()
      ..color = AppColors.brandRed
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    double current = offsetProgress;
    while (current < total) {
      final segStart = current;
      final segEnd = math.min(current + dashLength, total);
      if (segStart < total) {
        canvas.drawLine(
          a + direction * segStart,
          a + direction * segEnd,
          dashPaint,
        );
      }
      current += cycle;
    }
  }

  void _drawMovingAmbulance(Canvas canvas, Offset a, Offset b) {
    // Smooth moving ambulance traversing the route
    final progress = animValue;
    final currentPos = a + (b - a) * progress;

    // Outer beacon aura
    canvas.drawCircle(
      currentPos,
      12,
      Paint()..color = AppColors.brandRed.withValues(alpha: 0.25),
    );

    // Vehicle body circle
    canvas.drawCircle(currentPos, 7.5, Paint()..color = Colors.white);
    canvas.drawCircle(currentPos, 5.5, Paint()..color = AppColors.brandRed);

    // Cross sign
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(currentPos.dx - 2.5, currentPos.dy),
      Offset(currentPos.dx + 2.5, currentPos.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(currentPos.dx, currentPos.dy - 2.5),
      Offset(currentPos.dx, currentPos.dy + 2.5),
      crossPaint,
    );
  }

  void _drawEmergencyBeacon(Canvas canvas, Offset pos) {
    // Pulsing concentric radar ripples
    for (int i = 0; i < 3; i++) {
      final phase = (animValue + i / 3.0) % 1.0;
      final radius = 6.0 + phase * 28.0;
      final opacity = (1.0 - phase).clamp(0.0, 1.0) * 0.45;
      final ripplePaint = Paint()
        ..color = AppColors.brandRed.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(pos, radius, ripplePaint);
    }

    // Incident target core
    canvas.drawCircle(pos, 8, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 6, Paint()..color = AppColors.brandRed);
    canvas.drawCircle(pos, 2.5, Paint()..color = Colors.white);
  }

  void _drawUnitMarker(Canvas canvas, Offset pos, _MapUnitData unit) {
    final isSelected = selectedUnit?.id == unit.id;

    // Halo pulse for all units
    final pulse = (math.sin(animValue * 2 * math.pi) + 1) / 2;
    canvas.drawCircle(
      pos,
      isSelected ? 14 : 9 + 2 * pulse,
      Paint()
        ..color = unit.color.withValues(alpha: isSelected ? 0.35 : 0.15 + 0.1 * pulse),
    );

    // Marker base
    canvas.drawCircle(pos, isSelected ? 8 : 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(pos, isSelected ? 6 : 4.5, Paint()..color = unit.color);
  }

  @override
  bool shouldRepaint(covariant _EnhancedMapPainter oldDelegate) => true;
}

/// Slippy Map raster tile grid loading OpenStreetMap tiles for Addis Ababa.
class _OsmTileGrid extends StatelessWidget {
  final Size size;
  const _OsmTileGrid({required this.size});

  @override
  Widget build(BuildContext context) {
    // Zoom 13 tiles centered on Addis Ababa (lat 9.02, lon 38.74)
    const zoom = 13;
    const centerTileX = 4977;
    const centerTileY = 3894;
    final isDark = AppThemeController.isDark;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          Column(
            children: [
              for (int dy = -1; dy <= 1; dy++)
                Expanded(
                  child: Row(
                    children: [
                      for (int dx = -1; dx <= 1; dx++)
                        Expanded(
                          child: ColorFiltered(
                            colorFilter: isDark
                                ? const ColorFilter.matrix([
                                    -0.75, 0, 0, 0, 215,
                                    0, -0.75, 0, 0, 215,
                                    0, 0, -0.75, 0, 215,
                                    0, 0, 0, 1.0, 0,
                                  ])
                                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                            child: Image.network(
                              'https://tile.openstreetmap.org/$zoom/${centerTileX + dx}/${centerTileY + dy}.png',
                              fit: BoxFit.cover,
                              headers: const {'User-Agent': 'HiwonetDispatch/1.0'},
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                child: Center(
                                  child: Icon(
                                    Icons.map_outlined,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          // Softening overlay so dispatch markers, vectors & beacons stand out vividly
          Container(
            color: isDark
                ? const Color(0xFF0B0F19).withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}
