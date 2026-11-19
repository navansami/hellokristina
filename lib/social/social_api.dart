import 'dart:convert';

import 'package:http/http.dart' as http;

/// Someone you can follow, as search, lists and profile cards show them.
class Person {
  final String id, name, username;
  final Object? avatar;
  final int xp, streak, level;
  final bool youFollow, followsYou;
  const Person(
      {required this.id,
      required this.name,
      required this.username,
      this.avatar,
      this.xp = 0,
      this.streak = 0,
      this.level = 1,
      this.youFollow = false,
      this.followsYou = false});

  factory Person.fromJson(Map<String, dynamic> j) => Person(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      username: (j['username'] ?? '').toString(),
      avatar: j['avatar'],
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      level: (j['level'] as num?)?.toInt() ?? 1,
      youFollow: j['youFollow'] == true,
      followsYou: j['followsYou'] == true);

  Person copyWith({bool? youFollow}) => Person(
      id: id,
      name: name,
      username: username,
      avatar: avatar,
      xp: xp,
      streak: streak,
      level: level,
      youFollow: youFollow ?? this.youFollow,
      followsYou: followsYou);
}

/// A win in the feed: a finished lesson, a level-up or a streak milestone.
class FeedItem {
  final String id, type, lessonId, actorName, actorUsername;
  final Object? actorAvatar;
  final int xp, level, streak, likeCount;
  final bool mine, liked;
  final DateTime? createdAt;
  const FeedItem(
      {required this.id,
      required this.type,
      this.lessonId = '',
      this.actorName = '',
      this.actorUsername = '',
      this.actorAvatar,
      this.xp = 0,
      this.level = 0,
      this.streak = 0,
      this.likeCount = 0,
      this.mine = false,
      this.liked = false,
      this.createdAt});

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
      id: (j['id'] ?? '').toString(),
      type: (j['type'] ?? 'lesson').toString(),
      lessonId: (j['lessonId'] ?? '').toString(),
      actorName: (j['actorName'] ?? 'A learner').toString(),
      actorUsername: (j['actorUsername'] ?? '').toString(),
      actorAvatar: j['actorAvatar'],
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      level: (j['level'] as num?)?.toInt() ?? 0,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
      mine: j['mine'] == true,
      liked: j['liked'] == true,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()));

  FeedItem cheered(bool on) => FeedItem(
      id: id,
      type: type,
      lessonId: lessonId,
      actorName: actorName,
      actorUsername: actorUsername,
      actorAvatar: actorAvatar,
      xp: xp,
      level: level,
      streak: streak,
      likeCount: likeCount + (on ? 1 : -1),
      mine: mine,
      liked: on,
      createdAt: createdAt);
}

/// "just now", "5m", "3h", "2d", or a date for anything older than a week.
String timeAgo(DateTime? when, [DateTime? now]) {
  if (when == null) return '';
  final gap = (now ?? DateTime.now()).difference(when.toLocal());
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inHours < 1) return '${gap.inMinutes}m';
  if (gap.inDays < 1) return '${gap.inHours}h';
  if (gap.inDays < 7) return '${gap.inDays}d';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = when.toLocal();
  return '${local.day} ${months[local.month - 1]}';
}

class SocialError implements Exception {
  final String message;
  const SocialError(this.message);
  @override
  String toString() => message;
}

/// The follow and feed endpoints. Pass a [client] in tests.
class SocialApi {
  final Uri Function(String path) url;
  final String token;
  final http.Client? client;
  const SocialApi(this.url, this.token, {this.client});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _send(String method, String path,
      [Map<String, Object?>? body]) async {
    try {
      final request = http.Request(method, url(path))..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await (client?.send(request) ?? request.send());
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw SocialError((data['error'] ?? 'Something went wrong').toString());
      }
      return data;
    } on SocialError {
      rethrow;
    } catch (_) {
      throw const SocialError('Can’t reach Hello Kristina right now.');
    }
  }

  List<Person> _people(Object? raw) => [
        for (final p in (raw as List? ?? const []))
          Person.fromJson((p as Map).cast<String, dynamic>())
      ];

  Future<({List<Person> following, List<Person> followers})> lists() async {
    final data = await _send('GET', '/api/social/friends');
    return (
      following: _people(data['following'] ?? data['friends']),
      followers: _people(data['followers']),
    );
  }

  Future<List<Person>> search(String text) async {
    final data = await _send('GET',
        '/api/social/friends?q=${Uri.encodeQueryComponent(text.trim())}');
    return _people(data['results']);
  }

  Future<Person> follow(String username) async => Person.fromJson(((await _send(
              'POST', '/api/social/friends', {'username': username}))['person']
          as Map)
      .cast<String, dynamic>());

  Future<void> unfollow(String username) async {
    await _send('DELETE', '/api/social/friends', {'username': username});
  }

  Future<List<FeedItem>> feed() async {
    final data = await _send('GET', '/api/social/feed');
    return [
      for (final item in (data['items'] as List? ?? const []))
        FeedItem.fromJson((item as Map).cast<String, dynamic>())
    ];
  }

  Future<void> cheer(String itemId) async {
    await _send('POST', '/api/social/feed', {'itemId': itemId});
  }
}
