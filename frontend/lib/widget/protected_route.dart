// File: lib/widgets/protected_route.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    print('Current user: $user'); // Debug log for current user

    if (user == null) {
      print('Redirecting to auth page. User is null.'); // Log redirection reason
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
      });
      
      // Show a temporary loading spinner while the redirect happens
      return const Scaffold(
        backgroundColor: Color(0xFFF6FAFE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user is logged in, allow them to see the requested page
    return child;
  }
}