import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widget/chatbar.dart';

class DashboardWeb extends StatefulWidget {
  const DashboardWeb({super.key});

  @override
  State<DashboardWeb> createState() => _DashboardWebState();
}

class _DashboardWebState extends State<DashboardWeb> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;
  late Future<List<String>> _tipsFuture;

  final TextEditingController _incomeController = TextEditingController();
  double _taxDue = 0.0;
  bool _isCalculatingTax = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
    _tipsFuture = ApiService.getDashboardTips();
  }

  Future<void> _calculateTax(String value) async {
    if (value.isEmpty) {
      setState(() => _taxDue = 0.0);
      return;
    }
    setState(() => _isCalculatingTax = true);
    double income = double.tryParse(value) ?? 0.0;
    double tax = await ApiService.calculateTaxes(income);
    setState(() {
      _taxDue = tax;
      _isCalculatingTax = false;
    });
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
            
        double healthScore = total == 0 ? 100 : ((safe / total) * 100);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100), // Max width for web
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                        const SizedBox(height: 8),
                        Text('Showing data from $total scanned receipts', style: const TextStyle(color: Color(0xFF44617D), fontSize: 15)),
                      ],
                    ),
                    const Expanded(child: Padding(padding: EdgeInsets.only(left: 40), child: ChatBar())),
                  ],
                ),
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

                  // ── Web Layout: Split Content ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Fine Banner, Tax Calculator & Health
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildFineBanner(totalFine, danger),
                            const SizedBox(height: 24),
                            // Annual Income Calculator
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Estimated Taxes', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _incomeController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _calculateTax,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Annual Income (RM)',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Taxes to be Paid:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                  _isCalculatingTax 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text('RM ${_taxDue.toStringAsFixed(2)}', style: GoogleFonts.publicSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                ])
                              ]),
                            ),
                            const SizedBox(height: 24),
                            // Health Monitor
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: healthScore > 70 ? [Colors.green.shade700, Colors.green.shade500] : [Colors.orange.shade700, Colors.orange.shade500]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(children: [
                                const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Document Health Monitor', style: GoogleFonts.publicSans(color: Colors.white70, fontWeight: FontWeight.bold)),
                                    Text('${healthScore.toStringAsFixed(0)}% Safe', style: GoogleFonts.publicSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ]),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      
                      // Right Column: Tips & Activity
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI Tips
                            Text('AI Recommended Tax Tips', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                            const SizedBox(height: 16),
                            FutureBuilder<List<String>>(
                              future: _tipsFuture,
                              builder: (context, tipSnapshot) {
                                if (tipSnapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                                final tips = tipSnapshot.data ?? [];
                                return Column(
                                  children: tips.map((tip) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                                    child: Row(children: [
                                      const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(child: Text(tip, style: const TextStyle(fontSize: 15, height: 1.4))),
                                    ]),
                                  )).toList(),
                                );
                              }
                            ),
                            const SizedBox(height: 32),
                            // Activity
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