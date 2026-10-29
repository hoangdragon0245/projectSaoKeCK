import 'package:flutter/material.dart';
import '../screens/closed_trades_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/holdings_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transactions_screen.dart';

class ResponsiveScaffold extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ResponsiveScaffold({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    HoldingsScreen(),
    TransactionsScreen(),
    ClosedTradesScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Tổng quan tài sản',
    'Danh mục nắm giữ',
    'Sao kê giao dịch',
    'Hiệu suất chốt lời',
    'Cài đặt & Dữ liệu',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.show_chart, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  _titles[_currentIndex],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: widget.isDarkMode ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối',
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.onToggleTheme,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: isWideScreen
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                          labelType: NavigationRailLabelType.all,
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Icon(Icons.candlestick_chart, color: Colors.blue, size: 28),
                          ),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.dashboard_outlined),
                              selectedIcon: Icon(Icons.dashboard),
                              label: Text('Tổng quan'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.pie_chart_outline),
                              selectedIcon: Icon(Icons.pie_chart),
                              label: Text('Danh mục'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.receipt_long_outlined),
                              selectedIcon: Icon(Icons.receipt_long),
                              label: Text('Sao kê'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.emoji_events_outlined),
                              selectedIcon: Icon(Icons.emoji_events),
                              label: Text('Chốt lời'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings),
                              label: Text('Cài đặt'),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(child: _pages[_currentIndex]),
                      ],
                    )
                  : _pages[_currentIndex],
            ),
          ),
          bottomNavigationBar: isWideScreen
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Tổng quan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.pie_chart_outline),
                      selectedIcon: Icon(Icons.pie_chart),
                      label: 'Danh mục',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: 'Sao kê',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events),
                      label: 'Chốt lời',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Cài đặt',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
