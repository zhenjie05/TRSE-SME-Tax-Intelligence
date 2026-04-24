import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/chatbar.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  static const Color kNavy = Color(0xFF002753);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};

    final extracted = data['extracted_data'] as Map<String, dynamic>? ?? {};
    final glm       = data['glm']            as Map<String, dynamic>? ?? {};

    final status     = data['status']          ?? glm['verdict']   ?? 'UNKNOWN';
    final riskScore  = (data['risk_score']     ?? glm['risk_score'] ?? 0) as num;
    final confidence = (data['confidence_level'] ?? (glm['confidence'] != null ? (glm['confidence'] as num) / 100 : 0.0)) as num;

    final merchantName = extracted['merchant_name'] ?? 'Unknown';
    final tin          = extracted['tin']          ?? 'N/A';
    final totalAmount  = (extracted['total_amount'] ?? 0) as num;
    final taxAmount    = (extracted['tax_amount']   ?? 0) as num;
    final date         = extracted['date']          ?? 'N/A';

    final aiExplanation     = data['ai_explanation']     ?? glm['summary']  ?? 'N/A';
    final lhdnReference     = data['lhdn_reference']     ?? (glm['citations'] as List?)?.join(', ')          ?? 'N/A';
    final recommendation    = data['action_recommendation'] ?? (glm['tax_saving_tips'] as List?)?.first         ?? 'N/A';
    final impactSaved       = (data['impact_saved'] ?? glm['estimated_fine_rm'] ?? 0) as num;

    final tips     = glm['tax_saving_tips'] as List? ?? [];
    final citations = glm['citations']     as List? ?? [];
    final disclaimer = glm['disclaimer']   ?? data['disclaimer'] ?? 'For pre-audit analysis only. Consult a licensed tax advisor.';

    Color cardColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    if (status == 'SAFE')   { cardColor = Colors.green;  statusIcon = Icons.check_circle_rounded; }
    if (status == 'REVIEW') { cardColor = Colors.orange; statusIcon = Icons.warning_amber_rounded; }
    if (status == 'DANGER' || status == 'INVALID') { cardColor = Colors.red; statusIcon = Icons.dangerous_rounded; }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFE),
      appBar: AppBar(
        title: Text('Compliance Verdict', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ADDED: Chatbar with initial Context
          ChatBar(initialContext: data),
          const SizedBox(height: 16),

          // ── STATUS CARD ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardColor.withOpacity(0.07), border: Border.all(color: cardColor, width: 2.5), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: cardColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))]),
            child: Column(children: [
              Icon(statusIcon, size: 64, color: cardColor),
              const SizedBox(height: 8),
              Text(status, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: cardColor, letterSpacing: 2)),
              Text('${(confidence * 100).toStringAsFixed(0)}% Confidence', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              Row(children: [
                _metricTile('Fine Exposure', 'RM ${impactSaved.toStringAsFixed(0)}', Colors.red.shade50, Colors.red),
                const SizedBox(width: 8),
                _metricTile('Risk Score', '${riskScore.toInt()}/100', Colors.blue.shade50, Colors.blue),
                const SizedBox(width: 8),
                _metricTile('Tax Amount', 'RM ${taxAmount.toStringAsFixed(2)}', Colors.orange.shade50, Colors.orange),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── EXTRACTED DATA ───────────────────────────────────
          _sectionCard(icon: Icons.document_scanner, iconColor: kNavy, title: 'Extracted Receipt Data', child: Column(children: [_dataRow('Merchant', merchantName), _divider(), _dataRow('Tax ID (TIN)', tin, valueColor: tin == 'NOT_FOUND' ? Colors.red : Colors.black87), _divider(), _dataRow('Date', date), _divider(), _dataRow('Total Amount', 'RM ${totalAmount.toStringAsFixed(2)}', bold: true)])),

          // ── AI EXPLANATION ───────────────────────────────────
          _sectionCard(icon: Icons.psychology, iconColor: Colors.indigo, title: 'AI Analysis', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(aiExplanation, style: const TextStyle(fontSize: 13, height: 1.6))])),

          // ── LHDN CITATIONS ───────────────────────────────────
          _sectionCard(icon: Icons.gavel_rounded, iconColor: Colors.indigo, title: 'LHDN Citations', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: citations.isNotEmpty ? citations.map((c) => _bulletPoint(c.toString(), Colors.indigo)).toList() : [Text(lhdnReference, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13))])),

          // ── TAX SAVING TIPS ──────────────────────────────────
          _sectionCard(icon: Icons.lightbulb_rounded, iconColor: Colors.amber.shade700, title: 'Tax-Saving Recommendations', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: tips.isNotEmpty ? tips.map((t) => _bulletPoint(t.toString(), Colors.amber.shade700)).toList() : [_bulletPoint(recommendation.toString(), Colors.amber.shade700)])),

          // ── CAPITAL PROTECTED ────────────────────────────────
          Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)), child: Row(children: [Icon(Icons.savings_rounded, color: Colors.green.shade700, size: 28), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Potential Capital Protected', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)), Text('RM ${impactSaved.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700))])])),

          // ── DISCLAIMER ───────────────────────────────────────
          Container(margin: const EdgeInsets.only(bottom: 32), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, size: 15, color: Colors.grey.shade500), const SizedBox(width: 8), Expanded(child: Text(disclaimer, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5)))]))
        ]),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color bg, MaterialColor color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: color[700]), textAlign: TextAlign.center)])));
  }

  Widget _sectionCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: iconColor, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]), const SizedBox(height: 14), child])));
  }

  Widget _dataRow(String label, String value, {bool bold = false, Color valueColor = Colors.black87}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: valueColor)))]));
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _bulletPoint(String text, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.circle, size: 6, color: color), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)))]));
  }
}