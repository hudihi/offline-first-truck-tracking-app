import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/kago_theme.dart';
import 'package:intl/intl.dart';

// ─── Connectivity Badge ───────────────────────────────────────────────────────

class ConnectivityBadge extends StatelessWidget {
  final bool isOnline;
  const ConnectivityBadge({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? KagoTheme.green.withOpacity(0.15)
            : KagoTheme.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? KagoTheme.green.withOpacity(0.3)
              : KagoTheme.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: isOnline ? KagoTheme.green : KagoTheme.red),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOnline ? KagoTheme.green : KagoTheme.red,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

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

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color valueColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor = const Color(0xFFE8EAF0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KagoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KagoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
          )),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 22, fontWeight: FontWeight.w700,
            color: valueColor,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: KagoTheme.grey,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Offline Warning Banner ───────────────────────────────────────────────────

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    color: KagoTheme.red.withOpacity(0.06),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bolt, color: KagoTheme.red, size: 14),
        const SizedBox(width: 6),
        const Text(
          'Offline mode — data saved locally and will sync when connected',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: KagoTheme.red,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

// ─── Queue Item ───────────────────────────────────────────────────────────────

class QueueItem extends StatelessWidget {
  final SyncRecord record;
  const QueueItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isPending = record.status == SyncStatus.pending || record.status == SyncStatus.failed;
    final dotColor = isPending ? KagoTheme.amber : KagoTheme.green;
    final badgeText = record.status.label;
    final badgeBg = isPending
        ? KagoTheme.amber.withOpacity(0.12)
        : KagoTheme.green.withOpacity(0.10);
    final badgeBorder = isPending
        ? KagoTheme.amber.withOpacity(0.25)
        : KagoTheme.green.withOpacity(0.20);
    final badgeFg = isPending ? KagoTheme.amber : KagoTheme.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: KagoTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KagoTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.type.icon} ${record.type.label} · ${record.data['grossWeight'] ?? record.data['liters'] ?? '—'}',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk', fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(record.createdAt),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono', fontSize: 10, color: KagoTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: badgeBorder),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: badgeFg,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KagoButton ───────────────────────────────────────────────────────────────

class KagoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  const KagoButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: KagoTheme.orange,
            side: BorderSide(color: KagoTheme.orange.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ─── Hero Trip Card ───────────────────────────────────────────────────────────

class HeroTripCard extends StatelessWidget {
  final Trip trip;
  const HeroTripCard({super.key, required this.trip});

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KagoTheme.orange, KagoTheme.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20, right: 30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE TRIP · ${trip.id}',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${trip.origin} → ${trip.destination}',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroStat(label: 'Elapsed', value: _formatElapsed(trip.elapsed)),
                  const SizedBox(width: 16),
                  _HeroStat(label: 'Cargo', value: '${trip.cargoWeight}T'),
                  const SizedBox(width: 16),
                  _HeroStat(label: 'Driver', value: trip.driverName.split(' ').first),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk', fontSize: 15, fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk', fontSize: 11, color: Colors.white.withOpacity(0.7),
        ),
      ),
    ],
  );
}
