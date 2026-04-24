import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/chatbar.dart';

class ResultWeb extends StatefulWidget {
  const ResultWeb({super.key});

  @override
  State<ResultWeb> createState() => _ResultWebState();
}

class _ResultWebState extends State<ResultWeb> {
  static const Color kNavy = Color(0xFF002753);
  
  // State variables for manual overrides
  String? _manualTin;
  String? _localStatus;

  void _showTinDialog() {
    final TextEditingController tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter TIN Manually'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(
            labelText: 'Tax Identification Number',
            hintText: 'e.g. C1234567890',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tc.text.trim().isNotEmpty) {
                setState(() {
                  _manualTin = tc.text.trim();
                  _localStatus = 'SAFE'; // Instantly fix status!
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kNavy, foregroundColor: Colors.white),
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final extracted = data['extracted_data'] as Map<String, dynamic>? ?? {};
    
    // Dynamic logic based on user input
    final initialStatus = data['status'] ?? 'UNKNOWN';
    final status = _localStatus ?? initialStatus;
    
    final initialTin = extracted['tin'] ?? 'N/A';
    final tin = _manualTin ?? initialTin;
    
    final riskScore = (data['risk_score'] ?? 0) as num;
    final merchantName = extracted['merchant_name'] ?? 'Unknown';
    final totalAmount = (extracted['total_amount'] ?? 0) as num;
    
    Color cardColor = status == 'SAFE' ? Colors.green : (status == 'REVIEW' ? Colors.orange : Colors.red);
    IconData statusIcon = status == 'SAFE' ? Icons.check_circle : (status == 'REVIEW' ? Icons.warning : Icons.dangerous);

    // Logic to show Action Buttons
    bool needsAction = status == 'REVIEW' || tin == 'NOT_FOUND';

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
                              Text('Risk Score: ${status == 'SAFE' ? 0 : riskScore}/100', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
                                  Text(status == 'SAFE' ? 'TIN manually verified. The transaction is compliant.' : data['ai_explanation'] ?? 'N/A', style: const TextStyle(fontSize: 15, height: 1.6)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    
                    // RIGHT SIDE: Action Banner, Data & Citations
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // ── ACTION REQUIRED BANNER ───────────────────────────
                          if (needsAction) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                    SizedBox(width: 12),
                                    Text('Action Required', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 20)),
                                  ]),
                                  const SizedBox(height: 12),
                                  const Text('The AI flagged missing or unclear information. Please verify the TIN manually or scan the receipt again.', style: TextStyle(fontSize: 15, color: Colors.black87)),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.pop(context), // Routes back to the upload page
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Scan Again'),
                                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                        )
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _showTinDialog,
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Enter TIN Manually'),
                                          style: ElevatedButton.styleFrom(backgroundColor: kNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                                        )
                                      ),
                                    ]
                                  )
                                ]
                              )
                            ),
                            const SizedBox(height: 24),
                          ],

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Extracted Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Divider(height: 32),
                                  _dataRow('Merchant', merchantName),
                                  _dataRow('Tax ID (TIN)', tin, textColor: tin == 'NOT_FOUND' ? Colors.red : Colors.green.shade700, isBold: tin != initialTin),
                                  _dataRow('Total Amount', 'RM ${totalAmount.toStringAsFixed(2)}', isBold: true),
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

  Widget _dataRow(String label, String value, {bool isBold = false, Color textColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)), 
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor))
        ]
      )
    );
  }
}