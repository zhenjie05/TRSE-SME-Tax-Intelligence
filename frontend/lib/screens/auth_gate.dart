import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // To access MainLayout
import '../responsive_layout.dart';
import 'auth_mobile.dart';
import 'auth_web.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading spinner while checking session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        print('Session data: $session'); // Debug log for session data

        // If session exists, show Dashboard. If not, show Login.
        if (session != null) {
          return const MainLayout();
        } else {
          return const ResponsiveLayout(
            mobileView: AuthMobile(),
            webView: AuthWeb(),
          );
        }
      },
    );
  }
}