import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;
  String _currentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  void _refresh() => setState(() => _historyFuture = ApiService.fetchAuditHistory());

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
        
        // Filter Logic
        List<dynamic> displayData = [];
        if (snapshot.hasData) {
          if (_currentFilter == 'ALL') {
            displayData = snapshot.data!;
          } else {
            displayData = snapshot.data!.where((log) => log['status'] == _currentFilter).toList();
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          // New Upload Button (Routes back to the main layout that handles tabs)
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'), 
            backgroundColor: kNavy,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Upload', style: TextStyle(color: Colors.white)),
          ),
          body: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Audit Trail', style: GoogleFonts.publicSans(fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
                      const SizedBox(height: 16),
                      
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'SAFE', 'REVIEW', 'DANGER'].map((filter) {
                            bool isSelected = _currentFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
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
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (displayData.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No records match your filter.', style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final log = displayData[i];
                          final status = log['status'] ?? 'UNKNOWN';
                          final merchant = log['merchant_name'] ?? 'Unknown Merchant';
                          final amount = (log['total_amount'] ?? 0) as num;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                            child: Row(children: [
                              Icon(Icons.receipt_long, color: _getColorForFilter(status)),
                              const SizedBox(width: 14),
                              Expanded(child: Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text('RM ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ]),
                          );
                        },
                        childCount: displayData.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // padding for FAB
              ],
            ),
          ),
        );
      },
    );
  }
}