import 'package:flutter/material.dart';
import '../design_system.dart';

class ConfirmResignDialog extends StatelessWidget {
  const ConfirmResignDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignSystem.backgroundRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Row(
        children: [
          Icon(Icons.flag_rounded, color: DesignSystem.error, size: 24),
          SizedBox(width: 10),
          Text('Resign Game?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DesignSystem.textPrimary)),
        ],
      ),
      content: const Text(
        'Are you sure you want to resign? The engine will win this game.',
        style:
            TextStyle(fontSize: 14, color: DesignSystem.textMuted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(
                  color: DesignSystem.textMuted, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.error,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Resign',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmResignDialog(),
    );
    return result ?? false;
  }
}
