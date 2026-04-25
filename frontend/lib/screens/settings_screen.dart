import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color kNavy = Color(0xFF002753);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings',
            style: GoogleFonts.publicSans(
                fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 24),
        _tile(Icons.business, 'Business Profile', 'Set your MSIC code & TIN'),
        _tile(Icons.notifications_outlined, 'Notifications', 'Compliance alerts'),
        _tile(Icons.lock_outline, 'Privacy', 'Data handling preferences'),
        _tile(Icons.info_outline, 'About TSRE', 'Version 1.0.0 — UM Hackathon 2026'),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'For pre-audit analysis only.\nConsult a licensed tax advisor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.6),
          ),
        ),
      ]),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Icon(icon, color: kNavy, size: 22),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ]),
    );
  }
}