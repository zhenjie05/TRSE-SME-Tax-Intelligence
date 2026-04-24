import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        // ── Derive stats from real/mock data ──────────────────
        final logs = snapshot.data ?? [];
        final total  = logs.length;
        final safe   = logs.where((l) => l['status'] == 'SAFE').length;
        final review = logs.where((l) => l['status'] == 'REVIEW').length;
        final danger = logs.where((l) => l['status'] == 'DANGER').length;
        final totalFine = logs.fold<double>(
          0.0, (sum, l) => sum + ((l['total_amount'] ?? 0) as num).toDouble()
              * (l['status'] == 'DANGER' ? 0.24 : 0)); // estimated 24% fine exposure

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _historyFuture = ApiService.fetchAuditHistory());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Header ────────────────────────────────────────
              Text('Dashboard',
                  style: GoogleFonts.publicSans(
                      fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 4),
              Text(
                snapshot.connectionState == ConnectionState.waiting
                    ? 'Loading your compliance overview...'
                    : 'Showing data from $total scanned receipts',
                style: const TextStyle(color: Color(0xFF44617D), fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Loading State ─────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[

                // ── Stat Cards ────────────────────────────────
                Row(children: [
                  _statCard('Total Scanned', '$total',
                      Icons.receipt_long, Colors.blue),
                  const SizedBox(width: 12),
                  _statCard('Safe', '$safe',
                      Icons.check_circle, Colors.green),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _statCard('Review', '$review',
                      Icons.warning_amber, Colors.orange),
                  const SizedBox(width: 12),
                  _statCard('Danger', '$danger',
                      Icons.dangerous, Colors.red),
                ]),
                const SizedBox(height: 24),

                // ── Fine Exposure Banner ───────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF002753), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: kNavy.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text('ESTIMATED FINE EXPOSURE',
                          style: GoogleFonts.publicSans(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      'RM ${totalFine.toStringAsFixed(2)}',
                      style: GoogleFonts.publicSans(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Across $danger DANGER receipt${danger == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Recent Activity ────────────────────────────
                Text('Recent Activity',
                    style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kNavy)),
                const SizedBox(height: 12),

                if (logs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No receipts scanned yet.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...logs.take(3).map((log) => _activityTile(log)),
              ],
              const SizedBox(height: 40),
            ]),
          ),
        );
      },
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.publicSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kNavy)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> log) {
    final status = log['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'SAFE')   statusColor = Colors.green;
    if (status == 'REVIEW') statusColor = Colors.orange;
    if (status == 'DANGER') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.receipt_long, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(log['merchant_name'] ?? 'Unknown',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Risk Score: ${log['risk_score'] ?? 0}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            'RM ${(log['total_amount'] ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ),
        ]),
      ]),
    );
  }
}