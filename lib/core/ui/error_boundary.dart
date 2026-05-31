import 'package:flutter/material.dart';
import '../design_system.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String errorMessage;
  const ErrorBoundary(
      {super.key,
      required this.child,
      this.errorMessage = 'Something went wrong. Please restart the section.'});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignSystem.errorContainer.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignSystem.error.withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: DesignSystem.error, size: 40),
            const SizedBox(height: 12),
            Text(widget.errorMessage,
                style: const TextStyle(
                    color: DesignSystem.textPrimary, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() {
                _hasError = false;
              }),
              child: const Text('Try Again',
                  style: TextStyle(
                      color: DesignSystem.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return widget.child;
  }
}
