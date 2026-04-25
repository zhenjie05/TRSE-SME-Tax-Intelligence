import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsWeb extends StatelessWidget {
  const SettingsWeb({super.key});
  static const Color kNavy = Color(0xFF002753);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Settings', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
            const SizedBox(height: 32),
            _tile(Icons.business, 'Business Profile', 'Set your MSIC code & TIN'),
            _tile(Icons.notifications_outlined, 'Notifications', 'Compliance alerts'),
            _tile(Icons.lock_outline, 'Privacy', 'Data handling preferences'),
            _tile(Icons.info_outline, 'About TSRE', 'Version 1.0.0 — UM Hackathon 2026'),
          ]),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Icon(icon, color: kNavy, size: 28),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ])),
      ]),
    );
  }
}