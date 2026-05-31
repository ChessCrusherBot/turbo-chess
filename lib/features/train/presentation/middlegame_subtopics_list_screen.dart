import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'subtopics_list_base.dart';

class MiddlegameSubtopicsListScreen extends StatelessWidget {
  final OpeningTopic topic;
  final Color color;

  const MiddlegameSubtopicsListScreen({
    super.key,
    required this.topic,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SubtopicsListBaseScreen(
      title: 'Middlegame Drills',
      topic: topic,
      color: color,
      routeName: '/train/middlegame/drill',
    );
  }
}
