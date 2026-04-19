import 'package:flutter/material.dart';
import 'screens/upload_screen.dart'; // Make sure this is imported!
import 'screens/result_screen.dart'; 

void main() {
  runApp(const TSREApp());
}

class TSREApp extends StatelessWidget {
  const TSREApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSRE',
      theme: ThemeData(primarySwatch: Colors.blue),
      // This tells the app to load the UploadScreen first!
      initialRoute: '/', 
      routes: {
        '/': (context) => const UploadScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}