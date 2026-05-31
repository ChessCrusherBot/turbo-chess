import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'drill_detail_base.dart';

class MiddlegameDrillDetailScreen extends StatelessWidget {
  final OpeningTopic topic;
  final String subtopic;
  final Color color;
  final int difficulty;

  const MiddlegameDrillDetailScreen({
    super.key,
    required this.topic,
    required this.subtopic,
    required this.color,
    this.difficulty = 3,
  });

  @override
  Widget build(BuildContext context) {
    return DrillDetailBaseScreen(
      screenTitle: 'Middlegame Drills',
      topic: topic,
      subtopic: subtopic,
      color: color,
      difficulty: difficulty,
    );
  }
}
