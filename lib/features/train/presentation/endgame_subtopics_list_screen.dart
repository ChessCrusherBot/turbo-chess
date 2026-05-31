import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'subtopics_list_base.dart';

class EndgameSubtopicsListScreen extends StatelessWidget {
  final OpeningTopic topic;
  final Color color;

  const EndgameSubtopicsListScreen({
    super.key,
    required this.topic,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SubtopicsListBaseScreen(
      title: 'Endgame Drills',
      topic: topic,
      color: color,
      routeName: '/train/endgame/drill',
    );
  }
}
