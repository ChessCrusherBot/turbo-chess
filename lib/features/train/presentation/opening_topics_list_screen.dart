import 'package:flutter/material.dart';

import '../../../core/data/opening_drills.dart';
import 'topics_list_base.dart';

class OpeningTopicsListScreen extends StatelessWidget {
  const OpeningTopicsListScreen({super.key});

  static const List<Color> _topicColors = [
    Color(0xFF6AABDA),
    Color(0xFFE8C56E),
    Color(0xFFE87060),
    Color(0xFFA8D8E8),
    Color(0xFF90D890),
    Color(0xFFC8A8D8),
    Color(0xFFE8D468),
    Color(0xFFE8A868),
    Color(0xFF98D8B8),
    Color(0xFFD4C8A8),
    Color(0xFFE8906E),
    Color(0xFFC890D8),
    Color(0xFFE86870),
    Color(0xFF98B8D8),
    Color(0xFFC8D890),
    Color(0xFFD4C8A8),
    Color(0xFFB8A8D4),
    Color(0xFFD8A898),
    Color(0xFF98D8C8),
    Color(0xFFE89870),
  ];

  @override
  Widget build(BuildContext context) {
    final topics = OpeningDrillsData.allTopics;
    final subtopicCount = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.subtopics.length,
    );

    return TopicsListBaseScreen(
      title: 'Opening Drills',
      headerTitle: 'Opening Study',
      headerSubtitle: '${topics.length} topics | $subtopicCount subtopics',
      topics: topics,
      routeName: '/train/openings/subtopics',
      colorForTopic: (index, topic) =>
          topicAccentColor(topic, _topicColors[index % _topicColors.length]),
    );
  }
}
