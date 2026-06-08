import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../core/ui/confirm_leave_dialog.dart';
import '../data/play_computer_active_game_store.dart';

class ActivePlayComputerResumeCard extends StatefulWidget {
  const ActivePlayComputerResumeCard({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final EdgeInsetsGeometry padding;

  @override
  State<ActivePlayComputerResumeCard> createState() =>
      _ActivePlayComputerResumeCardState();
}

class _ActivePlayComputerResumeCardState
    extends State<ActivePlayComputerResumeCard> {
  static const PlayComputerActiveGameStore _store =
      PlayComputerActiveGameStore();

  PlayComputerActiveGameSnapshot? _snapshot;
  bool _hasUnusableSave = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasRawSave = await _store.hasSavedSnapshotData();
    final snapshot = hasRawSave ? await _store.load() : null;
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _hasUnusableSave = hasRawSave && snapshot == null;
      _loaded = true;
    });
  }

  Future<void> _discard() async {
    final confirmed = await ConfirmLeaveDialog.show(
      context,
      title: 'Discard unfinished game?',
      message: 'This will delete the saved game and its current moves.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Discard',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await _store.clear();
    if (!mounted) return;
    setState(() {
      _snapshot = null;
      _hasUnusableSave = false;
    });
  }

  Future<void> _resume() async {
    await Navigator.of(context).pushNamed(
      '/play/computer',
      arguments: const {'resumeActive': true},
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || (_snapshot == null && !_hasUnusableSave)) {
      return const SizedBox.shrink();
    }

    final snapshot = _snapshot;
    final body = snapshot == null
        ? 'This unfinished game cannot be restored.'
        : 'You have an unfinished game against the computer.';

    return Padding(
      padding: widget.padding,
      child: Container(
        key: const ValueKey('active_play_resume_card'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignSystem.backgroundRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DesignSystem.secondary.withAlpha(82)),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.secondary.withAlpha(18),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DesignSystem.secondary.withAlpha(24),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: DesignSystem.secondary.withAlpha(80),
                    ),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: DesignSystem.secondaryLight,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resume unfinished game?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DesignSystem.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: DesignSystem.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('discard_active_play_card'),
                  onPressed: _discard,
                  child: const Text('Discard'),
                ),
                const Spacer(),
                if (snapshot != null)
                  FilledButton.icon(
                    key: const ValueKey('resume_active_play_card'),
                    onPressed: _resume,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Resume'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
