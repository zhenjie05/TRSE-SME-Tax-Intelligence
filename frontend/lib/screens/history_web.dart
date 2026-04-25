import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HistoryWeb extends StatefulWidget {
  const HistoryWeb({super.key});
  @override
  State<HistoryWeb> createState() => _HistoryWebState();
}

class _HistoryWebState extends State<HistoryWeb> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;
  String _currentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  Color _getColorForFilter(String filter) {
    switch (filter) {
      case 'SAFE': return Colors.green;
      case 'REVIEW': return Colors.orange;
      case 'DANGER': return Colors.red;
      default: return kNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        
        List<dynamic> displayData = [];
        if (snapshot.hasData) {
          if (_currentFilter == 'ALL') {
            displayData = snapshot.data!;
          } else {
            displayData = snapshot.data!.where((log) => log['status'] == _currentFilter).toList();
          }
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Audit Trail', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('New Upload', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: kNavy, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Filter Row
                  Row(
                    children: ['ALL', 'SAFE', 'REVIEW', 'DANGER'].map((filter) {
                      bool isSelected = _currentFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : kNavy)),
                          selected: isSelected,
                          selectedColor: _getColorForFilter(filter),
                          onSelected: (selected) {
                            if (selected) setState(() => _currentFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (displayData.isEmpty)
                    const Expanded(child: Center(child: Text('No records match your filter.')))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, mainAxisExtent: 140, crossAxisSpacing: 20, mainAxisSpacing: 20),
                        itemCount: displayData.length,
                        itemBuilder: (context, i) {
                          final log = displayData[i];
                          final status = log['status'] ?? 'UNKNOWN';
                          Color sColor = _getColorForFilter(status);
                          
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.receipt, color: sColor),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  ],
                                ),
                                const Spacer(),
                                Text(log['merchant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Risk: ${log['risk_score']}', style: const TextStyle(color: Colors.grey)),
                                    Text('RM ${log['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}