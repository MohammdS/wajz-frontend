/// API models for the Wajz backend.
library;

class StoryListItem {
  const StoryListItem({
    required this.id,
    required this.headline,
    required this.summary,
    required this.category,
    required this.region,
    required this.confidenceLabel,
    required this.confidenceDisplay,
    required this.sourceCount,
    required this.sources,
    required this.imageUrl,
    required this.lastUpdatedAt,
    required this.saved,
    required this.contentLanguage,
  });

  final String id;
  final String headline;
  final String? summary;
  final String? category;
  final String? region;
  final String confidenceLabel;
  final String confidenceDisplay;
  final int sourceCount;
  final List<String> sources;
  final String? imageUrl;
  final DateTime lastUpdatedAt;
  final bool saved;
  final String contentLanguage;

  factory StoryListItem.fromJson(Map<String, dynamic> json) => StoryListItem(
    id: json['id'] as String,
    headline: json['headline'] as String,
    summary: json['summary'] as String?,
    category: json['category'] as String?,
    region: json['region'] as String?,
    confidenceLabel: json['confidence_label'] as String,
    confidenceDisplay: json['confidence_display'] as String,
    sourceCount: json['source_count'] as int,
    sources: (json['sources'] as List).cast<String>(),
    imageUrl: json['image_url'] as String?,
    lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
    saved: json['saved'] as bool? ?? false,
    contentLanguage: json['content_language'] as String? ?? 'en',
  );

  StoryListItem copyWith({bool? saved}) => StoryListItem(
    id: id,
    headline: headline,
    summary: summary,
    category: category,
    region: region,
    confidenceLabel: confidenceLabel,
    confidenceDisplay: confidenceDisplay,
    sourceCount: sourceCount,
    sources: sources,
    imageUrl: imageUrl,
    lastUpdatedAt: lastUpdatedAt,
    saved: saved ?? this.saved,
    contentLanguage: contentLanguage,
  );
}

class OngoingTopic {
  const OngoingTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.storyCount,
    required this.imageUrl,
    required this.lastUpdatedAt,
    required this.expiresAt,
    required this.contentLanguage,
  });

  final String id;
  final String title;
  final String description;
  final String? category;
  final int storyCount;
  final String? imageUrl;
  final DateTime lastUpdatedAt;
  final DateTime? expiresAt;
  final String contentLanguage;

  factory OngoingTopic.fromJson(Map<String, dynamic> json) => OngoingTopic(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String?,
    storyCount: json['story_count'] as int,
    imageUrl: json['image_url'] as String?,
    lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
    expiresAt: json['expires_at'] != null
        ? DateTime.parse(json['expires_at'] as String)
        : null,
    contentLanguage: json['content_language'] as String? ?? 'en',
  );
}

class OngoingTopicDetail {
  const OngoingTopicDetail({
    required this.topic,
    required this.stories,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final OngoingTopic topic;
  final List<StoryListItem> stories;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + stories.length < total;

  factory OngoingTopicDetail.fromJson(Map<String, dynamic> json) {
    final stories = json['stories'] as Map<String, dynamic>;
    return OngoingTopicDetail(
      topic: OngoingTopic.fromJson(json),
      stories: (stories['items'] as List)
          .map((item) => StoryListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: stories['total'] as int,
      limit: stories['limit'] as int,
      offset: stories['offset'] as int,
    );
  }
}

class SourceLink {
  const SourceLink({
    required this.name,
    required this.title,
    required this.url,
    required this.publishedAt,
  });

  final String name;
  final String title;
  final String url;
  final DateTime? publishedAt;

  factory SourceLink.fromJson(Map<String, dynamic> json) => SourceLink(
    name: json['name'] as String,
    title: json['title'] as String,
    url: json['url'] as String,
    publishedAt: json['published_at'] != null
        ? DateTime.parse(json['published_at'] as String)
        : null,
  );
}

class SourceComparison {
  const SourceComparison({required this.source, required this.framing});

  final String source;
  final String framing;

  factory SourceComparison.fromJson(Map<String, dynamic> json) =>
      SourceComparison(
        source: json['source'] as String,
        framing: json['framing'] as String,
      );
}

class StoryDetail {
  const StoryDetail({
    required this.id,
    required this.headline,
    required this.summary,
    required this.whatHappened,
    required this.whyItMatters,
    required this.keyFacts,
    required this.unclearPoints,
    required this.category,
    required this.region,
    required this.confidenceLabel,
    required this.confidenceDisplay,
    required this.sources,
    required this.sourceComparison,
    required this.lastUpdatedAt,
    required this.saved,
    required this.contentLanguage,
  });

  final String id;
  final String headline;
  final String? summary;
  final String? whatHappened;
  final String? whyItMatters;
  final List<String> keyFacts;
  final List<String> unclearPoints;
  final String? category;
  final String? region;
  final String confidenceLabel;
  final String confidenceDisplay;
  final List<SourceLink> sources;
  final List<SourceComparison> sourceComparison;
  final DateTime lastUpdatedAt;
  final bool saved;
  final String contentLanguage;

  factory StoryDetail.fromJson(Map<String, dynamic> json) => StoryDetail(
    id: json['id'] as String,
    headline: json['headline'] as String,
    summary: json['summary'] as String?,
    whatHappened: json['what_happened'] as String?,
    whyItMatters: json['why_it_matters'] as String?,
    keyFacts: (json['key_facts'] as List? ?? []).cast<String>(),
    unclearPoints: (json['unclear_points'] as List? ?? []).cast<String>(),
    category: json['category'] as String?,
    region: json['region'] as String?,
    confidenceLabel: json['confidence_label'] as String,
    confidenceDisplay: json['confidence_display'] as String,
    sources: (json['sources'] as List)
        .map((s) => SourceLink.fromJson(s as Map<String, dynamic>))
        .toList(),
    sourceComparison: (json['source_comparison'] as List? ?? [])
        .map((s) => SourceComparison.fromJson(s as Map<String, dynamic>))
        .toList(),
    lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
    saved: json['saved'] as bool? ?? false,
    contentLanguage: json['content_language'] as String? ?? 'en',
  );
}

class Briefing {
  const Briefing({
    required this.date,
    required this.briefingLength,
    required this.estimatedReadTimeMinutes,
    required this.greeting,
    this.displayName,
    required this.stories,
    required this.openedStoryIds,
    required this.completionMessage,
  });

  final String date;
  final String briefingLength;
  final int estimatedReadTimeMinutes;
  final String greeting;
  final String? displayName;
  final List<StoryListItem> stories;
  final Set<String> openedStoryIds;
  final String completionMessage;

  factory Briefing.fromJson(Map<String, dynamic> json) => Briefing(
    date: json['date'] as String,
    briefingLength: json['briefing_length'] as String,
    estimatedReadTimeMinutes: json['estimated_read_time_minutes'] as int,
    greeting: json['greeting'] as String,
    displayName: json['display_name'] as String?,
    stories: (json['stories'] as List)
        .map((s) => StoryListItem.fromJson(s as Map<String, dynamic>))
        .toList(),
    openedStoryIds: (json['opened_story_ids'] as List? ?? [])
        .cast<String>()
        .toSet(),
    completionMessage: json['completion_message'] as String,
  );
}

class Preferences {
  const Preferences({
    this.preferredLanguage = 'en',
    this.topics = const [],
    this.regions = const [],
    this.briefingLength = '10_minutes',
    this.explanationLevel = 'standard',
    this.notificationPreference = 'daily_morning',
    this.onboardingCompleted = false,
  });

  final String preferredLanguage;
  final List<String> topics;
  final List<String> regions;
  final String briefingLength;
  final String explanationLevel;
  final String notificationPreference;
  final bool onboardingCompleted;

  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    preferredLanguage: json['preferred_language'] as String? ?? 'en',
    topics: (json['topics'] as List? ?? []).cast<String>(),
    regions: (json['regions'] as List? ?? []).cast<String>(),
    briefingLength: json['briefing_length'] as String? ?? '10_minutes',
    explanationLevel: json['explanation_level'] as String? ?? 'standard',
    notificationPreference:
        json['notification_preference'] as String? ?? 'daily_morning',
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'preferred_language': preferredLanguage,
    'topics': topics,
    'regions': regions,
    'briefing_length': briefingLength,
    'explanation_level': explanationLevel,
    'notification_preference': notificationPreference,
    'onboarding_completed': onboardingCompleted,
  };

  Preferences copyWith({
    String? preferredLanguage,
    List<String>? topics,
    List<String>? regions,
    String? briefingLength,
    String? explanationLevel,
    String? notificationPreference,
    bool? onboardingCompleted,
  }) => Preferences(
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    topics: topics ?? this.topics,
    regions: regions ?? this.regions,
    briefingLength: briefingLength ?? this.briefingLength,
    explanationLevel: explanationLevel ?? this.explanationLevel,
    notificationPreference:
        notificationPreference ?? this.notificationPreference,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
}

class SavedStory {
  const SavedStory({required this.savedAt, required this.story});

  final DateTime savedAt;
  final StoryListItem story;

  factory SavedStory.fromJson(Map<String, dynamic> json) => SavedStory(
    savedAt: DateTime.parse(json['saved_at'] as String),
    story: StoryListItem.fromJson(json['story'] as Map<String, dynamic>),
  );
}

class CategoryInfo {
  const CategoryInfo({required this.categories, required this.regions});

  final List<String> categories;
  final List<String> regions;

  factory CategoryInfo.fromJson(Map<String, dynamic> json) => CategoryInfo(
    categories: (json['categories'] as List).cast<String>(),
    regions: (json['regions'] as List).cast<String>(),
  );
}
