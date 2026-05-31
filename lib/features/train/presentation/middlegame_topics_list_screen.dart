import 'package:flutter/material.dart';

import '../../../core/data/middlegame_drills.dart';
import 'topics_list_base.dart';

class MiddlegameTopicsListScreen extends StatelessWidget {
  const MiddlegameTopicsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = MiddlegameDrillsData.allTopics;
    final subtopicCount = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.subtopics.length,
    );

    return TopicsListBaseScreen(
      title: 'Middlegame Drills',
      headerTitle: 'Middlegame Study',
      headerSubtitle: '${topics.length} topics | $subtopicCount subtopics',
      topics: topics,
      routeName: '/train/middlegame/subtopics',
      colorForTopic: (_, topic) =>
          topicAccentColor(topic, const Color(0xFFE6C200)),
    );
  }
}
