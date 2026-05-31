import 'package:flutter/material.dart';
import '../core/design_system.dart';
import 'ui/animation_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// PREMIUM BUTTON COMPONENTS
/// ═══════════════════════════════════════════════════════════

/// Primary action button with glow effect and smooth animations
class PremiumButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? glowColor;
  final double? height;
  final double borderRadius;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.fullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.glowColor,
    this.height,
    this.borderRadius = 20.0,
    this.isLoading = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? DesignSystem.primary;
    final fgColor = widget.foregroundColor ?? DesignSystem.textPrimary;
    final glow = widget.glowColor ?? bgColor;

    return GestureDetector(
      onTapDown: _enabled ? (_) => _controller.forward() : null,
      onTapUp: _enabled
          ? (_) {
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: _enabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _enabled ? 1.0 : 0.5,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              height: widget.height ?? 56,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient:
                    LinearGradient(colors: [bgColor, bgColor.withAlpha(230)]),
                boxShadow: _controller.isCompleted
                    ? DesignSystem.shadowSm
                    : [
                        BoxShadow(color: glow.withAlpha(60), blurRadius: 24),
                        BoxShadow(
                            color: glow.withAlpha(30),
                            offset: const Offset(0, 4),
                            blurRadius: 12),
                      ],
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: fgColor, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fgColor, size: 20),
                          const SizedBox(width: 10)
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// PREMIUM CARD COMPONENTS
/// ═══════════════════════════════════════════════════════════

/// Interactive card with icon, title, and subtitle (used in Train/More screens)
class PremiumInteractiveCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final String? emojiIcon;
  final Widget? iconWidget;
  final Widget? trailing;

  const PremiumInteractiveCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.emojiIcon,
    this.iconWidget,
    this.trailing,
  });

  @override
  State<PremiumInteractiveCard> createState() => _PremiumInteractiveCardState();
}

class _PremiumInteractiveCardState extends State<PremiumInteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.accentColor.withAlpha(50)),
              boxShadow: _controller.isCompleted
                  ? DesignSystem.shadowSm
                  : [
                      BoxShadow(
                          color: widget.accentColor.withAlpha(20),
                          offset: const Offset(0, 4),
                          blurRadius: 16)
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.accentColor.withAlpha(42),
                        widget.accentColor.withAlpha(16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: widget.accentColor.withAlpha(68)),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withAlpha(18),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: widget.emojiIcon != null
                      ? Text(
                          widget.emojiIcon!,
                          style: const TextStyle(fontSize: 26),
                        )
                      : widget.iconWidget ??
                          Icon(
                            widget.icon,
                            color: widget.accentColor,
                            size: 27,
                          ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              color: DesignSystem.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: DesignSystem.textMuted,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),
                widget.trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: DesignSystem.textMuted, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Elevated card with subtle border and optional glow
class PremiumCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final Color? glowColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.borderRadius = 24,
    this.showBorder = true,
    this.borderColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? DesignSystem.backgroundRaised,
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(color: borderColor ?? DesignSystem.border)
              : null,
          boxShadow: glowColor != null
              ? [BoxShadow(color: glowColor!.withAlpha(40), blurRadius: 20)]
              : DesignSystem.shadowSm,
        ),
        child: child,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// PREMIUM CHIP COMPONENTS
/// ═══════════════════════════════════════════════════════════

/// Pill-shaped chip for tags, categories, etc.
class PremiumChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor = DesignSystem.textPrimary,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? DesignSystem.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
