import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'dart:developer' as _logger;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;

  static const Color kNavy = Color(0xFF002753);
  static const Color kNavyLight = Color(0xFF44617D);

  // ── Pickers ───────────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    if (!Platform.isWindows) {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (picked != null) setState(() => _selectedImage = picked);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not supported on Windows.'),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  // ── Analyse ───────────────────────────────────────────────────
  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    final result = await ApiService.analyzeReceipt(_selectedImage!);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null) {
      Navigator.pushNamed(context, '/result', arguments: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to backend engine.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildUploadCanvas(),
          const SizedBox(height: 14),
          _buildSecurityBanner(),
          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            _buildImagePreview(),
          ],
          const SizedBox(height: 24),
          _buildAnalyseButton(),
          const SizedBox(height: 32),
          _buildRecentUploadsHeader(),
          const SizedBox(height: 12),
          _RecentItem(
            title: 'INV-2026-089.pdf',
            subtitle: 'Today, 2:45 PM • 1.2 MB',
            status: 'PROCESSING',
          ),
          const SizedBox(height: 10),
          _RecentItem(
            title: 'Office_Supplies_Aug.jpg',
            subtitle: 'Yesterday • 840 KB',
            status: 'SAFE',
          ),
          const SizedBox(height: 32),
          _buildComplianceCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upload Document',
          style: GoogleFonts.publicSans(
              fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 6),
      const Text(
        'Add tax invoices or receipts for AI compliance analysis.',
        style: TextStyle(
            color: kNavyLight, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ]);
  }

  // ── Upload Canvas ─────────────────────────────────────────────
  Widget _buildUploadCanvas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavy.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: kNavy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_a_photo, color: kNavy, size: 32),
        ),
        const SizedBox(height: 20),
        Text('Take Photo or Upload',
            style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF171C1F))),
        const SizedBox(height: 6),
        const Text('Camera, PDF, JPG or PNG accepted',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Camera button
          ElevatedButton.icon(
            onPressed: _pickFromCamera,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text('CAMERA',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavy,
              foregroundColor: Colors.white,
              elevation: 4,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          // Files button
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.file_present, size: 18),
            label: Text('FILES',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Security Banner ───────────────────────────────────────────
  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_user, color: kNavy, size: 20),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Secure OCR processing: All documents are encrypted and PII is removed before AI analysis.',
            style: TextStyle(
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: kNavy),
          ),
        ),
      ]),
    );
  }

  // ── Image Preview ─────────────────────────────────────────────
  Widget _buildImagePreview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Selected Receipt',
          style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold, fontSize: 15, color: kNavy)),
      const SizedBox(height: 10),
      Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? Image.network(_selectedImage!.path,
                  height: 200, width: double.infinity, fit: BoxFit.cover)
              : Image.file(File(_selectedImage!.path),
                  height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImage = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // File name tag
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8)),
            child: Text(
              _selectedImage!.name.length > 25
                  ? '${_selectedImage!.name.substring(0, 25)}...'
                  : _selectedImage!.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ── Analyse Button ────────────────────────────────────────────
  Widget _buildAnalyseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            (_selectedImage != null && !_isLoading) ? _analyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kNavy,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isLoading
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)),
                const SizedBox(width: 14),
                Text('Analysing receipt...',
                    style: GoogleFonts.publicSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.document_scanner, color: Colors.white),
                const SizedBox(width: 10),
                Text('Analyse Receipt',
                    style: GoogleFonts.publicSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ]),
      ),
    );
  }

  // ── Recent Uploads Header ─────────────────────────────────────
  Widget _buildRecentUploadsHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
        'RECENT UPLOADS',
        style: GoogleFonts.publicSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey),
      ),
      TextButton(
        onPressed: () {},
        child: const Text('View All',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kNavy)),
      ),
    ]);
  }

  // ── Compliance Card ───────────────────────────────────────────
  Widget _buildComplianceCard() {
    return Container(
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
              color: kNavy.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text('LHDN 2026 Compliance Engine',
              style: GoogleFonts.publicSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        Text('AI-Powered Pre-Audit Intelligence',
            style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        const Text(
          'Upload a receipt above to get an instant compliance verdict with LHDN citations and tax-saving tips.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 18),
        Row(children: [
          _statChip('15 Rules', Icons.gavel),
          const SizedBox(width: 10),
          _statChip('Z.AI GLM', Icons.psychology),
          const SizedBox(width: 10),
          _statChip('Real-time', Icons.bolt),
        ]),
      ]),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── Recent Item Widget ────────────────────────────────────────────
class _RecentItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status; // 'SAFE', 'REVIEW', 'DANGER', 'PROCESSING'

  const _RecentItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    bool isProcessing = status == 'PROCESSING';

    switch (status) {
      case 'SAFE':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REVIEW':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
        break;
      case 'DANGER':
        statusColor = Colors.red;
        statusIcon = Icons.dangerous;
        break;
      default:
        statusColor = const Color(0xFF002753);
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.description, color: statusColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            isProcessing
                ? const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(strokeWidth: 1.5))
                : Icon(statusIcon, color: statusColor, size: 12),
            const SizedBox(width: 5),
            Text(status,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ]),
        ),
      ]),
    );
  }
}