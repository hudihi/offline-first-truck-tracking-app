import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kago_theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    // Refresh elapsed time every minute
    _elapsedTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final trip = app.activeTrip;
        final pending = app.pendingRecords.length;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              if (trip != null) HeroTripCard(trip: trip),

              // Network status grid
              const SectionTitle('Network Status'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    StatCard(
                      label: 'Connection',
                      value: app.isOnline ? 'Good' : 'Offline',
                      subtitle: app.isOnline ? '4G · -72 dBm' : 'No signal',
                      valueColor: app.isOnline ? KagoTheme.green : KagoTheme.red,
                    ),
                    StatCard(
                      label: 'Dead zones today',
                      value: '${app.deadZones.length}',
                      subtitle: '${app.totalDeadZoneMinutes} min total offline',
                      valueColor: KagoTheme.amber,
                    ),
                    StatCard(
                      label: 'Pending sync',
                      value: '$pending',
                      subtitle: pending == 0 ? 'all synced' : 'records queued',
                      valueColor: pending == 0 ? KagoTheme.green : KagoTheme.amber,
                    ),
                    StatCard(
                      label: 'Sync records',
                      value: '${app.syncRecords.length}',
                      subtitle: 'total this trip',
                      valueColor: const Color(0xFFE8EAF0),
                    ),
                  ],
                ),
              ),

              // Pending banner (only if there are pending records)
              if (pending > 0) ...[
                const SectionTitle('Pending Upload'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PendingBanner(
                    count: pending,
                    onTap: () => DefaultTabController.of(context).animateTo(1),
                  ),
                ),
              ],

              // Manual sync button (only if online + pending)
              if (app.isOnline && pending > 0) ...[
                const SectionTitle('Actions'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: KagoButton(
                    label: app.isSyncing ? 'Syncing…' : 'Sync $pending Record${pending > 1 ? 's' : ''} Now',
                    icon: Icons.cloud_upload_outlined,
                    isLoading: app.isSyncing,
                    onPressed: () => context.read<AppProvider>().triggerSync(),
                  ),
                ),
              ],

              // Trip info summary
              if (trip != null) ...[
                const SectionTitle('Trip Details'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TripInfoCard(trip: trip),
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

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KagoTheme.amber.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KagoTheme.amber.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count record${count > 1 ? 's' : ''} awaiting sync',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KagoTheme.amber,
                    ),
                  ),
                  const Text(
                    'Saved offline · will upload automatically',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KagoTheme.amber, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  final trip;
  const _TripInfoCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KagoTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KagoTheme.border),
      ),
      child: Column(
        children: [
          _InfoRow('Trip ID', trip.id),
          _InfoRow('Driver', trip.driverName),
          _InfoRow('Truck', trip.truckPlate),
          _InfoRow('Origin', trip.origin),
          _InfoRow('Destination', trip.destination),
          _InfoRow('Cargo', '${trip.cargoWeight}T', isLast: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(
                fontFamily: 'SpaceGrotesk', fontSize: 13, color: KagoTheme.grey,
              )),
              Text(value, style: const TextStyle(
                fontFamily: 'IBMPlexMono', fontSize: 12, color: Color(0xFFE8EAF0),
              )),
            ],
          ),
        ),
        if (!isLast) Divider(color: KagoTheme.border, height: 1),
      ],
    );
  }
}
