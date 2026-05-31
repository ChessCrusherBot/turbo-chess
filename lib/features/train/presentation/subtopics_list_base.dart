import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/models/models.dart';
import 'topics_list_base.dart';

class SubtopicsListBaseScreen extends StatelessWidget {
  final String title;
  final OpeningTopic topic;
  final Color color;
  final String routeName;

  const SubtopicsListBaseScreen({
    super.key,
    required this.title,
    required this.topic,
    required this.color,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.label),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withAlpha(56)),
                    ),
                    alignment: Alignment.center,
                    child: TurboIcon(
                      kind: topicIconKindFor(topic),
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: DesignSystem.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${topic.subtopics.length} subtopics',
                          style: const TextStyle(color: DesignSystem.textMuted),
                        ),
                        const AdFreeCompactStatusLine(
                          padding: EdgeInsets.only(top: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: topic.subtopics.length,
                itemBuilder: (context, index) {
                  final subtopic = topic.subtopics[index];
                  final semanticIcon =
                      TurboIconMapper.subtopicIconFor(topic, subtopic);

                  return Padding(
                    key: ValueKey('${topic.id}_$index'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          routeName,
                          arguments: {
                            'topic': topic,
                            'subtopic': subtopic,
                            'color': color,
                            'difficulty': 3,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignSystem.backgroundRaised,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withAlpha(38),
                                    color.withAlpha(14),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: color.withAlpha(58)),
                              ),
                              alignment: Alignment.center,
                              child: TurboIcon(
                                kind: semanticIcon,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                subtopic,
                                style: const TextStyle(
                                  color: DesignSystem.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: DesignSystem.textMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
