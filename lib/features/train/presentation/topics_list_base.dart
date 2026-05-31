import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/models/models.dart';
import '../../../core/ui_components.dart';

typedef TopicColorResolver = Color Function(int index, OpeningTopic topic);

Color topicAccentColor(OpeningTopic topic, Color fallback) {
  final rawColor = topic.color;
  if (rawColor == null) return fallback;

  final hex = rawColor.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16);
  if (hex.length != 6 || value == null) return fallback;

  return Color(0xFF000000 | value);
}

TurboIconKind topicIconKindFor(OpeningTopic topic) =>
    TurboIconMapper.categoryIconFor(topic);

class TopicsListBaseScreen extends StatefulWidget {
  final String title;
  final String headerTitle;
  final String headerSubtitle;
  final List<OpeningTopic> topics;
  final String routeName;
  final TopicColorResolver colorForTopic;

  const TopicsListBaseScreen({
    super.key,
    required this.title,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.topics,
    required this.routeName,
    required this.colorForTopic,
  });

  @override
  State<TopicsListBaseScreen> createState() => _TopicsListBaseScreenState();
}

class _TopicsListBaseScreenState extends State<TopicsListBaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTopics = widget.topics.where((topic) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return topic.label.toLowerCase().contains(query) ||
          topic.subtopics.any((item) => item.toLowerCase().contains(query));
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search topics...',
                  hintStyle: const TextStyle(color: DesignSystem.textMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: DesignSystem.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: DesignSystem.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            const AdFreeCompactStatusLine(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.headerTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: DesignSystem.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.headerSubtitle,
                    style: const TextStyle(color: DesignSystem.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredTopics.isEmpty
                  ? Center(
                      child: Text(
                        'No topics matching "$_searchQuery"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DesignSystem.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredTopics.length,
                      itemBuilder: (context, index) {
                        final topic = filteredTopics[index];
                        final topicIndex = widget.topics.indexOf(topic);
                        final accentColor =
                            widget.colorForTopic(topicIndex, topic);
                        return Padding(
                          key: ValueKey(topic.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TopicCard(
                            topic: topic,
                            accentColor: accentColor,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                widget.routeName,
                                arguments: {
                                  'topic': topic,
                                  'color': accentColor
                                },
                              );
                            },
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

class _TopicCard extends StatelessWidget {
  final OpeningTopic topic;
  final Color accentColor;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumInteractiveCard(
      icon: Icons.auto_stories_rounded,
      iconWidget: TurboIcon(
        kind: topicIconKindFor(topic),
        color: accentColor,
        size: 30,
      ),
      title: topic.label,
      subtitle: '${topic.subtopics.length} subtopics',
      accentColor: accentColor,
      onTap: onTap,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: DesignSystem.textMuted,
        size: 24,
      ),
    );
  }
}
