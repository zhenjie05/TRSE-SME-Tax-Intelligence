import 'history_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Needed to check if running on Web
import 'dart:io';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _selectedImage; // Changed from File to XFile
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);
    
    // Shoot the image to the Python backend
    final result = await ApiService.analyzeReceipt(_selectedImage!);
    
    setState(() { _result = result; _isLoading = false; });
    
    if (result != null) {
      Navigator.pushNamed(context, '/result', arguments: result);
    } else {
      // Show an error if the server is off or fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to backend engine.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TSRE — Upload Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to the History Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    // Safe Image rendering for Web vs Mobile
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb 
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 60, color: Colors.blue),
                          SizedBox(height: 12),
                          Text('Tap to upload receipt', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedImage != null && !_isLoading) ? _analyze : null,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Analysing receipt...'),
                        ])
                    : const Text('Analyse Receipt', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}