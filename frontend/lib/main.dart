import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mobile Imports
import 'screens/upload_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_gate.dart';

// Web Imports
import 'screens/dashboard_web.dart';
import 'screens/upload_web.dart';
import 'screens/history_web.dart';
import 'screens/result_web.dart';
import 'screens/settings_web.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_web.dart';

void main() async{
  // Ensure Flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Replace with your actual URL and Anon Key from Supabase Dashboard)
  await Supabase.initialize(
    url: 'https://lsiybeghfxavoeykylmo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzaXliZWdoZnhhdm9leWt5bG1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1OTM3NDUsImV4cCI6MjA5MjE2OTc0NX0.FZUeNm1nktuwT1k1wud-q-EuAqngtMJL8XHjMiT7KuA',
  );

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
        '/': (context) => const AuthGate(),
        // Result Screen is also responsive!
        '/result': (context) => const ResponsiveLayout(
              mobileView: ResultScreen(),
              webView: ResultWeb(),
            ),
        '/chat': (context) => const ResponsiveLayout(
              mobileView: ChatScreen(),
              webView: ChatWeb(),
            ),
        '/upload': (context) => const ResponsiveLayout(
              mobileView: UploadScreen(),
              webView: UploadWeb(),
            )
      },
    );
  }
}

final ValueNotifier<int> appTabIndex = ValueNotifier<int>(0);

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // We removed "int _selectedIndex = 0;" and are using appTabIndex instead!

  final List<Widget> _screens = [
    const ResponsiveLayout(mobileView: DashboardScreen(), webView: DashboardWeb()),
    const ResponsiveLayout(mobileView: HistoryScreen(), webView: HistoryWeb()),
    const ResponsiveLayout(mobileView: UploadScreen(), webView: UploadWeb()),
    const ResponsiveLayout(mobileView: SettingsScreen(), webView: SettingsWeb()),
  ];

  @override
  void initState() {
    super.initState();
    // 2. Tell the layout to redraw whenever the global tab index changes
    appTabIndex.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: isWeb
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: appTabIndex.value, // Use global index
                  onDestinationSelected: (i) => appTabIndex.value = i, // Update global index
                  extended: true,
                  backgroundColor: Colors.white,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('History')),
                    NavigationRailDestination(icon: Icon(Icons.cloud_upload_outlined), selectedIcon: Icon(Icons.cloud_upload), label: Text('Upload')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[appTabIndex.value]), 
              ],
            )
          : _screens[appTabIndex.value], 

      bottomNavigationBar: isWeb ? null : NavigationBar(
        selectedIndex: appTabIndex.value, // Use global index
        onDestinationSelected: (i) => appTabIndex.value = i, // Update global index
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