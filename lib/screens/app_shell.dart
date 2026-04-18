import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kago_theme.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'data_entry_screen.dart';
import 'dead_zone_map_screen.dart';
import 'activity_logs_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = [
    DashboardScreen(),
    DataEntryScreen(),
    DeadZoneMapScreen(),
    ActivityLogsScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.edit_document), activeIcon: Icon(Icons.edit_document), label: 'Data Entry'),
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Dead Zones'),
    BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline), label: 'Logs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: KagoTheme.darkBg,
            appBar: _buildAppBar(app),
            body: Column(
              children: [
                // Offline warning banner
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: app.isOnline
                      ? const SizedBox.shrink()
                      : const OfflineBanner(),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: KagoTheme.border, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                items: _navItems,
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppProvider app) {
    return AppBar(
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'KAGO ',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8EAF0),
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: 'AFRICA',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KagoTheme.orange,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ConnectivityBadge(isOnline: app.isOnline),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: KagoTheme.border, height: 1),
      ),
    );
  }
}
