import 'package:flutter/material.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/design_system.dart';
import '../../../core/ui_components.dart';

class SessionSummaryScreen extends StatelessWidget {
  final String topicName;

  const SessionSummaryScreen({
    super.key,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    final title = topicName.trim().isEmpty ? 'Training' : topicName.trim();

    return Scaffold(
      backgroundColor: DesignSystem.backgroundBase,
      body: SafeArea(
        top: true,
        bottom: false,
        child: AdScreenFrame(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DesignSystem.backgroundRaised,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DesignSystem.border),
                    boxShadow: DesignSystem.shadowMd,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: DesignSystem.primary.withAlpha(22),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: DesignSystem.primaryLight,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Training Complete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: DesignSystem.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: DesignSystem.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PremiumButton(
                  text: 'Continue Training',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pop(context),
                  fullWidth: true,
                  backgroundColor: DesignSystem.primary,
                  glowColor: DesignSystem.primary,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
