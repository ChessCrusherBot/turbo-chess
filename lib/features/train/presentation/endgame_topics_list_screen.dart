import 'package:flutter/material.dart';

import '../../../core/data/endgame_drills.dart';
import 'topics_list_base.dart';

class EndgameTopicsListScreen extends StatelessWidget {
  const EndgameTopicsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = EndgameDrillsData.allTopics;
    final subtopicCount = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.subtopics.length,
    );

    return TopicsListBaseScreen(
      title: 'Endgame Drills',
      headerTitle: 'Endgame Study',
      headerSubtitle: '${topics.length} topics | $subtopicCount subtopics',
      topics: topics,
      routeName: '/train/endgame/subtopics',
      colorForTopic: (_, topic) =>
          topicAccentColor(topic, const Color(0xFF10B981)),
    );
  }
}
