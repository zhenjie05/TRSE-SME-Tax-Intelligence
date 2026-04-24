import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_layout.dart';

// Mobile Imports
import 'screens/upload_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

// Web Imports
import 'screens/dashboard_web.dart';
import 'screens/upload_web.dart';
import 'screens/history_web.dart';
import 'screens/result_web.dart';
import 'screens/settings_web.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_web.dart';

void main() {
  runApp(const TSREApp());
}

class TSREApp extends StatelessWidget {
  const TSREApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TSRE',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002753), surface: const Color(0xFFF6FAFE)),
        textTheme: GoogleFonts.publicSansTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainLayout(),
        // Result Screen is also responsive!
        '/result': (context) => const ResponsiveLayout(
              mobileView: ResultScreen(),
              webView: ResultWeb(),
            ),
        '/chat': (context) => const ResponsiveLayout(
              mobileView: ChatScreen(),
              webView: ChatWeb(),
            )
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 2; // Default to Upload tab

  // ── THE RESPONSIVE MAGIC HAPPENS HERE ──
  final List<Widget> _screens = const [
    ResponsiveLayout(mobileView: DashboardScreen(), webView: DashboardWeb()),
    ResponsiveLayout(mobileView: HistoryScreen(),   webView: HistoryWeb()),
    ResponsiveLayout(mobileView: UploadScreen(),    webView: UploadWeb()),
    ResponsiveLayout(mobileView: SettingsScreen(),  webView: SettingsWeb()),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine if we are on a wide Web screen to show the Side Navigation Rail
    // Or a narrow Mobile screen to show the Bottom Navigation Bar
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(children: [
          const Icon(Icons.account_balance, color: Color(0xFF002753)),
          const SizedBox(width: 12),
          Text('TSRE Web', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: const Color(0xFF002753))),
        ]),
      ),
      
      // If Web, use Row for Side Menu. If Mobile, just show the screen.
      body: isWeb 
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('History')),
                  NavigationRailDestination(icon: Icon(Icons.cloud_upload_outlined), selectedIcon: Icon(Icons.cloud_upload), label: Text('Upload')),
                  NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // Expanded fills the rest of the screen with the selected Web View
              Expanded(child: _screens[_selectedIndex]), 
            ],
          )
        : _screens[_selectedIndex], // Mobile just displays the screen directly

      // If Mobile, show Bottom Navigation. If Web, hide it (return null).
      bottomNavigationBar: isWeb ? null : NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.history_outlined), label: 'History'),
          NavigationDestination(icon: Icon(Icons.cloud_upload_outlined), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}