import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TSREApp());
}

class TSREApp extends StatelessWidget {
  const TSREApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF002753),
        scaffoldBackgroundColor: const Color(0xFFF6FAFE),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: Container(
            color: const Color(0xFFF0F4F8).withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF002753), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'TSRE',
                      style: GoogleFonts.publicSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF002753),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC3C6D2).withOpacity(0.3)),
                    image: const DecorationImage(
                      image: NetworkImage('https://lh3.googleusercontent.com/...')
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeroRiskCard(),
            const SizedBox(height: 24),
            const FinancialOverview(),
            const SizedBox(height: 32),
            const TaxInsightsSection(),
            const SizedBox(height: 32),// Space for chat bar
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AIChatBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class HeroRiskCard extends StatelessWidget {
  const HeroRiskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF002753), Color(0xFF003D7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOCUMENT HEALTH MONITOR',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Audit Risk Profile',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Color(0xFFCEE5FF)),
                    const SizedBox(width: 6),
                    Text(
                      'OPTIMIZED',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFCEE5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Low',
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HEALTH SCORE',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '94%',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.94,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFCEE5FF)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Audit risk is historically low. All critical documents verified.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FinancialOverview extends StatelessWidget {
  const FinancialOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatCard(
          label: 'TAXES TO BE PAID',
          value: 'MYR 12,450.00',
          icon: Icons.account_balance_wallet,
          chipText: 'DUE IN 14 DAYS',
          isCritical: true,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          label: 'ANNUAL INCOME (YTD)',
          value: 'MYR 245,000.00',
          icon: Icons.trending_up,
          subtext: 'Self-declared for 2024 fiscal year',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    String? chipText,
    String? subtext,
    bool isCritical = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC3C6D2).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF737781),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: const Color(0xFF002753).withOpacity(0.4), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.publicSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF002753),
            ),
          ),
          if (chipText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 12, color: const Color(0xFFBA1A1A)),
                  const SizedBox(width: 8),
                  Text(
                    chipText,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFBA1A1A),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
          if (subtext != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(radius: 3, backgroundColor: Color(0xFF002753)),
                const SizedBox(width: 8),
                Text(
                  subtext,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF434750)),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}

class TaxInsightsSection extends StatelessWidget {
  const TaxInsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI TAX INSIGHTS',
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFF002753),
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          color: const Color(0xFFFFDBCA).withOpacity(0.3),
          icon: Icons.lightbulb,
          iconColor: const Color(0xFF692B00),
          title: 'Deduction Opportunity',
          description: 'Based on your recent hardware purchases, you can claim up to MYR 2,500 under digital tool incentives.',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          color: const Color(0xFFBFDDFE).withOpacity(0.3),
          icon: Icons.bolt,
          iconColor: const Color(0xFF002753),
          title: 'Compliance Tip',
          description: 'Ensure all utility bills are under the business name to maximize operational expense claims.',
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: iconColor.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AIChatBar extends StatelessWidget {
  const AIChatBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFC3C6D2).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF002753), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ask TSRE AI about your taxes...',
              style: TextStyle(color: Color(0xFF737781), fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          const Icon(Icons.send, color: Color(0xFFC3C6D2), size: 18),
        ],
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.dashboard, 'DASHBOARD'),
          _navItem(1, Icons.history, 'HISTORY'),
          _navItem(2, Icons.cloud_upload, 'UPLOAD'),
          _navItem(3, Icons.settings, 'SETTINGS'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFCEE5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF002753) : const Color(0xFF737781), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: active ? const Color(0xFF002753) : const Color(0xFF737781),
              ),
            ),
          ],
        ),
      ),
    );
  }
}