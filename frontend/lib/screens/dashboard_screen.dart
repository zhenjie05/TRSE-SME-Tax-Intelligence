import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widget/chatbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        
        // Document Health Monitor logic
        double healthScore = total == 0 ? 100 : ((safe / total) * 100);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _historyFuture = ApiService.fetchAuditHistory();
              _tipsFuture = ApiService.getDashboardTips();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dashboard', style: GoogleFonts.publicSans(fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 16),
              
              // 1. AI Chatbox
              const ChatBar(),
              const SizedBox(height: 24),

              // 2. Annual Income & Tax to be Paid
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Estimated Taxes', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    onChanged: _calculateTax,
                    decoration: InputDecoration(
                      labelText: 'Enter Annual Income (RM)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Current Taxes to be Paid:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    _isCalculatingTax 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('RM ${_taxDue.toStringAsFixed(2)}', style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  ])
                ]),
              ),
              const SizedBox(height: 24),

              // 3. Document Health Monitor & Risk Score
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: healthScore > 70 ? [Colors.green.shade700, Colors.green.shade500] : [Colors.orange.shade700, Colors.orange.shade500]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Document Health Monitor', style: GoogleFonts.publicSans(color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text('${healthScore.toStringAsFixed(0)}% Safe', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // 4. AI Recommended Tax Tips
              Text('AI Recommended Tax Tips', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _tipsFuture,
                builder: (context, tipSnapshot) {
                  if (tipSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final tips = tipSnapshot.data ?? [];
                  return Column(
                    children: tips.map((tip) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade200)),
                      child: Row(children: [
                        const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, height: 1.4))),
                      ]),
                    )).toList(),
                  );
                }
              ),
              const SizedBox(height: 24),

              // Existing Recent Activity
              Text('Recent Activity', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 12),
              if (logs.isEmpty) const Text('No receipts scanned yet.', style: TextStyle(color: Colors.grey))
              else ...logs.take(3).map((log) => _activityTile(log)),
            ]),
          ),
        );
      },
    );
  }

  Widget _activityTile(Map<String, dynamic> log) {
    final status = log['status'] ?? 'UNKNOWN';
    Color statusColor = status == 'SAFE' ? Colors.green : (status == 'REVIEW' ? Colors.orange : Colors.red);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Icon(Icons.receipt_long, color: statusColor, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log['merchant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('Risk Score: ${log['risk_score'] ?? 0}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Text('RM ${(log['total_amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}