import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design_system.dart';
import 'ad_free_service.dart';
import 'premium_pass_duration.dart';

class AdFreeStatusCopy {
  static String compactLine(AdFreeStatus status) {
    if (status.hasActiveSubscription) {
      return 'Premium active via Google Play';
    }
    if (status.shouldShowVerificationMessage) {
      return 'Ad-free status could not be verified';
    }
    if (status.hasRewardedPass) {
      return activeUntilLine(status);
    }
    return 'Ad-free active - ${remainingCompact(status.remainingDuration)}';
  }

  static String moreScreenStatus(AdFreeStatus status) {
    if (status.hasActiveSubscription) {
      return 'Premium active via Google Play';
    }
    if (status.hasRewardedPass) {
      return activeUntilLine(status);
    }
    if (status.shouldShowVerificationMessage) {
      return 'Ad-free status could not be verified. Please reconnect to the internet.';
    }
    return 'Ads active';
  }

  static String rewardedPassHeadline(AdFreeStatus status) {
    if (status.hasActiveSubscription) {
      return 'Subscription active';
    }
    if (status.hasRewardedPass) {
      return activeUntilLine(status);
    }
    if (status.shouldShowVerificationMessage) {
      return 'Verification required';
    }
    return rewardedPremiumPassTitle;
  }

  static String activeUntilLine(AdFreeStatus status) {
    final adFreeUntil = status.rewardedPassExpiresAt;
    if (adFreeUntil == null) {
      return '';
    }
    return 'Premium Pass active until ${formattedDate(adFreeUntil)}';
  }

  static String formattedDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    return DateFormat('MMM d, h:mm a').format(value.toLocal());
  }

  static String remainingCompact(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final days = safeDuration.inDays;
    final hours = safeDuration.inHours.remainder(24);
    final minutes = math.max(1, safeDuration.inMinutes.remainder(60));

    if (days > 0) {
      return hours > 0
          ? '${days}d ${hours}h left'
          : '$days day${days == 1 ? '' : 's'} left';
    }
    if (safeDuration.inHours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} left';
    }
    return '$minutes min left';
  }

  static String remainingLong(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final days = safeDuration.inDays;
    final hours = safeDuration.inHours.remainder(24);
    final minutes = math.max(1, safeDuration.inMinutes.remainder(60));

    if (days > 0) {
      return hours > 0
          ? '$days day${days == 1 ? '' : 's'} ${hours} hour${hours == 1 ? '' : 's'} left'
          : '$days day${days == 1 ? '' : 's'} left';
    }
    if (safeDuration.inHours > 0) {
      return minutes > 0
          ? '${safeDuration.inHours} hour${safeDuration.inHours == 1 ? '' : 's'} $minutes min left'
          : '${safeDuration.inHours} hour${safeDuration.inHours == 1 ? '' : 's'} left';
    }
    return '$minutes min left';
  }
}

class AdFreeCompactStatusLine extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AdFreeCompactStatusLine({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdFreeService.instance,
      builder: (context, _) {
        final status = AdFreeService.instance.status;
        if (!status.isAdFree && !status.shouldShowVerificationMessage) {
          return const SizedBox.shrink();
        }

        final isWarning = status.shouldShowVerificationMessage;
        return Padding(
          padding: padding,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isWarning
                  ? DesignSystem.warningContainer.withAlpha(170)
                  : DesignSystem.tertiary.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWarning
                    ? DesignSystem.warning.withAlpha(90)
                    : DesignSystem.tertiary.withAlpha(55),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isWarning
                        ? DesignSystem.warning.withAlpha(24)
                        : DesignSystem.tertiary.withAlpha(24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isWarning
                        ? Icons.verified_user_outlined
                        : Icons.visibility_off_rounded,
                    size: 16,
                    color: isWarning
                        ? DesignSystem.warningLight
                        : DesignSystem.tertiaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AdFreeStatusCopy.compactLine(status),
                    style: const TextStyle(
                      color: DesignSystem.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
