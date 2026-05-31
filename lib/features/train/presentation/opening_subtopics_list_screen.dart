import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'subtopics_list_base.dart';

class OpeningSubtopicsListScreen extends StatelessWidget {
  final OpeningTopic topic;
  final Color color;

  const OpeningSubtopicsListScreen({
    super.key,
    required this.topic,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SubtopicsListBaseScreen(
      title: 'Opening Drills',
      topic: topic,
      color: color,
      routeName: '/train/openings/drill',
    );
  }
}
