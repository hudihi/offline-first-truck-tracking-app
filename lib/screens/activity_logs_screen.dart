import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/kago_theme.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final trip = app.activeTrip;
        final logs = app.tripLogs;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip header
              if (trip != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: KagoTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KagoTheme.border),
                    ),
                    child: Row(
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('TRIP ID', style: TextStyle(
                            fontFamily: 'SpaceGrotesk', fontSize: 10, color: KagoTheme.grey,
                          )),
                          Text(trip.id, style: const TextStyle(
                            fontFamily: 'IBMPlexMono', fontSize: 15, fontWeight: FontWeight.w600,
                            color: Color(0xFFE8EAF0),
                          )),
                        ]),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: KagoTheme.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KagoTheme.green.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              _PulseDot(color: KagoTheme.green),
                              SizedBox(width: 6),
                              Text('In Progress', style: TextStyle(
                                fontFamily: 'SpaceGrotesk', fontSize: 11, fontWeight: FontWeight.w600,
                                color: KagoTheme.green,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Stats bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _LogStat(value: '${logs.length}', label: 'events', color: const Color(0xFFE8EAF0)),
                    const SizedBox(width: 10),
                    _LogStat(
                      value: '${logs.where((l) => l.eventType == LogEventType.networkLost).length}',
                      label: 'drops',
                      color: KagoTheme.red,
                    ),
                    const SizedBox(width: 10),
                    _LogStat(
                      value: '${logs.where((l) => l.eventType == LogEventType.dataSynced).length}',
                      label: 'syncs',
                      color: KagoTheme.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Timeline
              if (logs.isEmpty)
                const _EmptyLogs()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(logs.length, (i) {
                      final log = logs[i];
                      final isLast = i == logs.length - 1;
                      return _TimelineItem(log: log, isLast: isLast);
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Timeline Item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final TripLog log;
  final bool isLast;
  const _TimelineItem({required this.log, required this.isLast});

  Color _nodeColor() {
    switch (log.eventType) {
      case LogEventType.tripStarted:
      case LogEventType.tripEnded:
        return KagoTheme.orange;
      case LogEventType.networkLost:
      case LogEventType.deadZoneEntered:
        return KagoTheme.red;
      case LogEventType.networkRestored:
      case LogEventType.deadZoneExited:
        return KagoTheme.green;
      case LogEventType.dataSynced:
        return KagoTheme.green;
      case LogEventType.dataSavedOffline:
        return KagoTheme.amber;
      case LogEventType.checkpointReached:
        return KagoTheme.amber;
    }
  }

  Color _textColor() {
    switch (log.eventType) {
      case LogEventType.networkLost:
      case LogEventType.deadZoneEntered:
        return KagoTheme.red;
      case LogEventType.networkRestored:
      case LogEventType.dataSynced:
      case LogEventType.deadZoneExited:
        return KagoTheme.green;
      case LogEventType.dataSavedOffline:
        return KagoTheme.amber;
      case LogEventType.tripStarted:
        return KagoTheme.orange;
      default:
        return const Color(0xFFE8EAF0);
    }
  }

  bool get _filled {
    return log.eventType == LogEventType.tripStarted ||
        log.eventType == LogEventType.tripEnded ||
        log.eventType == LogEventType.networkLost ||
        log.eventType == LogEventType.networkRestored;
  }

  String _timePrefix() {
    final t = DateFormat('HH:mm').format(log.timestamp);
    switch (log.eventType) {
      case LogEventType.networkLost:   return '$t — Network went down';
      case LogEventType.networkRestored: return '$t — Network restored';
      case LogEventType.dataSynced:    return '$t — Auto-sync triggered';
      default: return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = _nodeColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spine
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: _filled ? nodeColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: nodeColor.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_timePrefix(), style: const TextStyle(
                    fontFamily: 'IBMPlexMono', fontSize: 10, color: KagoTheme.grey,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    '${log.eventType.icon}  ${log.eventType.label}',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w500,
                      color: _textColor(),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(log.detail, style: const TextStyle(
                    fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 7, height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class _LogStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _LogStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: KagoTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KagoTheme.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.w700,
            color: color,
          )),
          Text(label, style: const TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 10, color: KagoTheme.grey,
            letterSpacing: 0.5,
          )),
        ],
      ),
    ),
  );
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: const [
          Text('📡', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text('No events yet', style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 14, color: KagoTheme.grey,
          )),
          SizedBox(height: 4),
          Text('Events will appear here as the trip progresses', style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
          ), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
