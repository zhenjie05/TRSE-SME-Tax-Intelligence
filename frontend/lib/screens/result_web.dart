import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/chatbar.dart';

class ResultWeb extends StatelessWidget {
  const ResultWeb({super.key});
  static const Color kNavy = Color(0xFF002753);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final extracted = data['extracted_data'] as Map<String, dynamic>? ?? {};
    
    final status = data['status'] ?? 'UNKNOWN';
    final riskScore = (data['risk_score'] ?? 0) as num;
    final merchantName = extracted['merchant_name'] ?? 'Unknown';
    final totalAmount = (extracted['total_amount'] ?? 0) as num;
    
    Color cardColor = status == 'SAFE' ? Colors.green : (status == 'REVIEW' ? Colors.orange : Colors.red);
    IconData statusIcon = status == 'SAFE' ? Icons.check_circle : (status == 'REVIEW' ? Icons.warning : Icons.dangerous);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFE),
      appBar: AppBar(title: const Text('Compliance Verdict'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                // ADDED Chatbar with initial Context
                ChatBar(initialContext: data),
                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE: Status & Explanation
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(color: cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: cardColor, width: 2)),
                            child: Column(children: [
                              Icon(statusIcon, size: 80, color: cardColor),
                              const SizedBox(height: 16),
                              Text(status, style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: cardColor)),
                              const SizedBox(height: 16),
                              Text('Risk Score: $riskScore/100', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.psychology, color: Colors.indigo), SizedBox(width: 8), Text('AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 16),
                                  Text(data['ai_explanation'] ?? 'N/A', style: const TextStyle(fontSize: 15, height: 1.6)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    
                    // RIGHT SIDE: Data & Citations
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Extracted Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Divider(height: 32),
                                  _dataRow('Merchant', merchantName),
                                  _dataRow('Tax ID (TIN)', extracted['tin'] ?? 'N/A'),
                                  _dataRow('Total Amount', 'RM ${totalAmount.toStringAsFixed(2)}', bold: true),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            color: Colors.amber.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LHDN Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  Text(data['action_recommendation'] ?? 'N/A', style: const TextStyle(fontSize: 15, height: 1.5)),
                                  const Divider(height: 32),
                                  Text('LHDN Reference: ${data['lhdn_reference']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value, {bool bold = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)), Text(value, style: TextStyle(fontSize: 16, fontWeight: bold ? FontWeight.bold : FontWeight.normal))]));
  }
}