import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DashboardWeb extends StatefulWidget {
  const DashboardWeb({super.key});

  @override
  State<DashboardWeb> createState() => _DashboardWebState();
}

class _DashboardWebState extends State<DashboardWeb> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final total = logs.length;
        final safe = logs.where((l) => l['status'] == 'SAFE').length;
        final review = logs.where((l) => l['status'] == 'REVIEW').length;
        final danger = logs.where((l) => l['status'] == 'DANGER').length;
        final totalFine = logs.fold<double>(
            0.0, (sum, l) => sum + ((l['total_amount'] ?? 0) as num).toDouble() * (l['status'] == 'DANGER' ? 0.24 : 0));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100), // Max width for web
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dashboard', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 8),
                Text('Showing data from $total scanned receipts', style: const TextStyle(color: Color(0xFF44617D), fontSize: 15)),
                const SizedBox(height: 32),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
                else ...[
                  // ── Web Layout: All 4 stats in one Row ──
                  Row(children: [
                    _statCard('Total Scanned', '$total', Icons.receipt_long, Colors.blue),
                    const SizedBox(width: 16),
                    _statCard('Safe', '$safe', Icons.check_circle, Colors.green),
                    const SizedBox(width: 16),
                    _statCard('Review', '$review', Icons.warning_amber, Colors.orange),
                    const SizedBox(width: 16),
                    _statCard('Danger', '$danger', Icons.dangerous, Colors.red),
                  ]),
                  const SizedBox(height: 32),

                  // ── Web Layout: Split Fine Exposure and Activity ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFineBanner(totalFine, danger),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Activity', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                            const SizedBox(height: 16),
                            if (logs.isEmpty)
                              const Text('No receipts scanned yet.', style: TextStyle(color: Colors.grey))
                            else
                              ...logs.take(4).map((log) => _activityTile(log)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFineBanner(double totalFine, int danger) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF002753), Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Text('ESTIMATED FINE EXPOSURE', style: GoogleFonts.publicSans(color: Colors.white70, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        Text('RM ${totalFine.toStringAsFixed(2)}', style: GoogleFonts.publicSans(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Across $danger DANGER receipt${danger == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.publicSans(fontSize: 26, fontWeight: FontWeight.bold, color: kNavy)),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> log) {
    final status = log['status'] ?? 'UNKNOWN';
    Color statusColor = status == 'SAFE' ? Colors.green : (status == 'REVIEW' ? Colors.orange : Colors.red);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Icon(Icons.receipt_long, color: statusColor),
        const SizedBox(width: 16),
        Expanded(child: Text(log['merchant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
        Text('RM ${(log['total_amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}