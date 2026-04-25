import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget webView;

  const ResponsiveLayout({
    super.key,
    required this.mobileView,
    required this.webView,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen width is less than 600 pixels, it's a mobile screen
        if (constraints.maxWidth < 600) {
          return mobileView;
        } 
        // Otherwise, it's a web/desktop screen
        else {
          return webView;
        }
      },
    );
  }
}