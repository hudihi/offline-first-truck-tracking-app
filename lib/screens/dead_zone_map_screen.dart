import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/kago_theme.dart';
import '../widgets/common_widgets.dart';

class DeadZoneMapScreen extends StatelessWidget {
  const DeadZoneMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final deadZones = app.deadZones;
        final totalMinutes = app.totalDeadZoneMinutes;
        final coverage = deadZones.isEmpty
            ? 100
            : (100 - (totalMinutes / 480 * 100)).clamp(0, 100).round();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _RoutePainter(deadZones: deadZones),
                    ),
                  ),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KagoTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KagoTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MAP LEGEND', style: TextStyle(
                        fontFamily: 'SpaceGrotesk', fontSize: 11,
                        color: KagoTheme.grey, letterSpacing: 0.6,
                      )),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: const [
                          _LegendItem(color: KagoTheme.orange, label: 'Driver position'),
                          _LegendItem(color: KagoTheme.red, label: 'Dead zone'),
                          _LegendItem(color: KagoTheme.green, label: 'Good signal'),
                          _LegendItem(color: KagoTheme.amber, label: 'Weak signal'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Route stats
              const SectionTitle('Route Summary'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: StatCard(
                      label: 'Dead zones',
                      value: '${deadZones.length}',
                      valueColor: KagoTheme.red,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(
                      label: 'Offline time',
                      value: '${totalMinutes}m',
                      valueColor: KagoTheme.amber,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(
                      label: 'Coverage',
                      value: '$coverage%',
                      valueColor: KagoTheme.green,
                    )),
                  ],
                ),
              ),

              // Dead zone list
              if (deadZones.isNotEmpty) ...[
                const SectionTitle('Dead Zone Details'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: deadZones.asMap().entries.map((e) =>
                      _DeadZoneCard(zone: e.value, index: e.key + 1),
                    ).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
        fontFamily: 'SpaceGrotesk', fontSize: 11, color: Color(0xFFE8EAF0),
      )),
    ],
  );
}

class _DeadZoneCard extends StatelessWidget {
  final DeadZone zone;
  final int index;
  const _DeadZoneCard({required this.zone, required this.index});

  @override
  Widget build(BuildContext context) {
    final duration = zone.duration;
    final isActive = zone.recoveredAt == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KagoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? KagoTheme.red.withOpacity(0.3) : KagoTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: KagoTheme.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'DZ-$index',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 10,
                  fontWeight: FontWeight.w600, color: KagoTheme.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lat ${zone.latitude.toStringAsFixed(4)}, Lng ${zone.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono', fontSize: 11, color: KagoTheme.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  duration != null
                      ? '${duration.inMinutes}m ${duration.inSeconds % 60}s offline'
                      : 'Currently offline',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk', fontSize: 12,
                    color: isActive ? KagoTheme.red : KagoTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: KagoTheme.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: KagoTheme.red.withOpacity(0.25)),
              ),
              child: const Text('LIVE', style: TextStyle(
                fontFamily: 'SpaceGrotesk', fontSize: 9, fontWeight: FontWeight.w700,
                color: KagoTheme.red, letterSpacing: 0.4,
              )),
            ),
        ],
      ),
    );
  }
}

// ── Route Painter ─────────────────────────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  final List<DeadZone> deadZones;
  const _RoutePainter({required this.deadZones});

  // Route waypoints [x%, y%] normalized 0-1 within the map canvas
  static const _waypoints = [
    [0.07, 0.78],  // Dar es Salaam
    [0.30, 0.72],  // Chalinze
    [0.46, 0.58],  // Morogoro
    [0.55, 0.44],  // Mikumi
    [0.72, 0.30],  // Iringa
    [0.90, 0.18],  // Mbeya
  ];

  static const _cityLabels = [
    ['Dar es Salaam', 0.05, 0.88],
    ['Chalinze', 0.26, 0.83],
    ['Morogoro', 0.40, 0.68],
    ['Mikumi', 0.51, 0.54],
    ['Iringa', 0.69, 0.40],
    ['Mbeya', 0.88, 0.28],
  ];

  // Signal quality dots [x%, y%, quality: 0=good, 1=weak, 2=dead]
  static const _signalDots = [
    [0.14, 0.76, 0],
    [0.22, 0.73, 0],
    [0.38, 0.61, 1],
    [0.48, 0.50, 1],
    [0.63, 0.37, 0],
    [0.86, 0.21, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1B2E),
    );

    final w = size.width;
    final h = size.height;

    // Road shadow
    final roadShadow = Paint()
      ..color = const Color(0xFF2A3F5A)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadFill = Paint()
      ..color = const Color(0xFF1E4D7A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    roadFill.shader = const LinearGradient(
      colors: [Color(0xFF1E4D7A), Color(0xFF2563A8)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    path.moveTo(_waypoints[0][0] * w, _waypoints[0][1] * h);
    for (int i = 1; i < _waypoints.length; i++) {
      final prev = _waypoints[i - 1];
      final curr = _waypoints[i];
      final cpx = (prev[0] + curr[0]) / 2 * w;
      final cpy = (prev[1] + curr[1]) / 2 * h;
      path.quadraticBezierTo(
        cpx, cpy,
        curr[0] * w, curr[1] * h,
      );
    }

    canvas.drawPath(path, roadShadow);
    final dashPaint = Paint()
      ..color = const Color(0xFF1E4D7A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, dashPaint, 8, 5);

    // Dead zone halos
    final haloPaint = Paint()..style = PaintingStyle.fill;
    final haloStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Map dead zone positions to map coordinates (demo: fixed positions)
    final dzPositions = [
      [0.30, 0.72],
      [0.63, 0.37],
      if (deadZones.length > 2) [0.80, 0.24],
    ];

    for (int i = 0; i < dzPositions.length && i < 3; i++) {
      final x = dzPositions[i][0] * w;
      final y = dzPositions[i][1] * h;

      haloPaint.color = const Color(0xFFEF233C).withOpacity(0.08);
      haloStroke.color = const Color(0xFFEF233C).withOpacity(0.25);
      canvas.drawCircle(Offset(x, y), 28, haloPaint);
      canvas.drawCircle(Offset(x, y), 28, haloStroke);

      haloPaint.color = const Color(0xFFEF233C).withOpacity(0.15);
      canvas.drawCircle(Offset(x, y), 14, haloPaint);

      // DZ label
      _drawText(canvas, 'DZ-0${i + 1}', x - 14, y + 18, 8, const Color(0xCCEF233C), mono: true);
    }

    // Signal quality dots
    for (final dot in _signalDots) {
      final color = dot[2] == 0
          ? const Color(0xFF06D6A0)
          : dot[2] == 1
              ? const Color(0xFFFFB703)
              : const Color(0xFFEF233C);
      canvas.drawCircle(
        Offset(dot[0] * w, dot[1] * h),
        3,
        Paint()..color = color.withOpacity(0.7),
      );
    }

    // City labels
    for (final city in _cityLabels) {
      _drawText(canvas, city[0] as String, city[1] * w, city[2] * h,
          9, const Color(0xFF8B8FA8));
    }

    // Driver position (animated-like pulsing not possible in CustomPainter without ticker)
    final driverX = _waypoints[3][0] * w;
    final driverY = _waypoints[3][1] * h;
    canvas.drawCircle(Offset(driverX, driverY), 12,
        Paint()..color = KagoTheme.orange.withOpacity(0.2));
    canvas.drawCircle(Offset(driverX, driverY), 7,
        Paint()..color = KagoTheme.orange);
    canvas.drawCircle(Offset(driverX, driverY), 3.5,
        Paint()..color = Colors.white);

    // Driver label
    _drawText(canvas, '▲ You', driverX + 10, driverY - 8, 9, KagoTheme.orange);

    // Destination star
    _drawText(canvas, '★', _waypoints.last[0] * w - 6, _waypoints.last[1] * h + 4,
        14, KagoTheme.amber.withOpacity(0.9));
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color, {bool mono = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: mono ? 'IBMPlexMono' : 'SpaceGrotesk',
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final len = drawing ? dashLen : gapLen;
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.deadZones.length != deadZones.length;
}
