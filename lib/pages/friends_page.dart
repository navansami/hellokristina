part of '../main.dart';

/// Friends, Duolingo-style: follow people (no approval needed), see a
/// leaderboard of you and the people you follow, and cheer their wins.
class FriendsPage extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? me;
  final int xp;
  final LearnerLook look;
  final http.Client? client;
  const FriendsPage(
      {super.key,
      required this.token,
      this.me,
      this.xp = 0,
      this.look = const LearnerLook(),
      this.client});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Person> following = [], followers = [], results = [];
  List<FeedItem> feed = [];
  bool loaded = false, searching = false;
  String query = '';
  Timer? _debounce;
  final search = TextEditingController();

  SocialApi? get social => widget.token == null
      ? null
      : SocialApi(api, widget.token!, client: widget.client);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant FriendsPage old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token) {
      setState(() {
        following = [];
        followers = [];
        feed = [];
        loaded = false;
      });
      load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final social = this.social;
    if (social == null) return;
    try {
      final results = await Future.wait([social.lists(), social.feed()]);
      final lists =
          results[0] as ({List<Person> following, List<Person> followers});
      if (!mounted) return;
      setState(() {
        following = lists.following;
        followers = lists.followers;
        feed = results[1] as List<FeedItem>;
        loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => loaded = true);
    }
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    setState(() => query = text.trim());
    if (query.replaceFirst('@', '').length < 2) {
      setState(() {
        results = [];
        searching = false;
      });
      return;
    }
    setState(() => searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final asked = query;
      try {
        final found = await social!.search(asked);
        if (mounted && query == asked) {
          setState(() {
            results = found;
            searching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => searching = false);
      }
    });
  }

  /// Follow or unfollow, updating every list straight away.
  Future<void> _toggleFollow(Person person) async {
    final follow = !person.youFollow;
    // A cheerful chime when you follow someone, a soft tap to unfollow.
    if (follow) {
      learningFeedback.answer(true, 1);
    } else {
      learningFeedback.tap();
    }
    void swap(Person updated) {
      List<Person> replace(List<Person> list) =>
          [for (final p in list) p.id == updated.id ? updated : p];
      results = replace(results);
      followers = replace(followers);
      following = follow
          ? [...following.where((p) => p.id != updated.id), updated]
          : following.where((p) => p.id != updated.id).toList();
    }

    setState(() => swap(person.copyWith(youFollow: follow)));
    try {
      if (follow) {
        await social!.follow(person.username);
      } else {
        await social!.unfollow(person.username);
      }
      // Their wins appear (or disappear) in the feed.
      final fresh = await social!.feed();
      if (mounted) setState(() => feed = fresh);
    } on SocialError catch (e) {
      if (!mounted) return;
      setState(() => swap(person));
      _toast(e.message);
    }
  }

  Future<void> _cheer(FeedItem item) async {
    final on = !item.liked;
    learningFeedback.tap();
    setState(() => feed = [
          for (final f in feed) f.id == item.id ? f.cheered(on) : f,
        ]);
    try {
      await social!.cheer(item.id);
    } on SocialError {
      if (mounted) {
        setState(() => feed = [
              for (final f in feed) f.id == item.id ? f.cheered(!on) : f,
            ]);
      }
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content:
            Text(text, style: const TextStyle(fontWeight: FontWeight.w800))));

  String get _myUsername => (widget.me?['username'] ?? '').toString();

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: '@$_myUsername'));
    learningFeedback.touch();
    _toast('Copied @$_myUsername. Share it so friends can follow you!');
  }

  void _showPerson(Person person) {
    learningFeedback.touch();
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: bg,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(builder: (context, setSheet) {
              final current = [...following, ...followers, ...results]
                  .firstWhere((p) => p.id == person.id, orElse: () => person);
              return SafeArea(
                  child: _PersonSheet(
                      person: current,
                      onToggle: () async {
                        await _toggleFollow(current);
                        setSheet(() {});
                      }));
            }));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sign in to follow friends.',
                  style: TextStyle(color: muted))));
    }
    final theme = unitTheme(5);
    final searchingNow = query.replaceFirst('@', '').length >= 2;
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: [
              _SearchField(
                  controller: search,
                  onChanged: _onSearch,
                  onClear: () {
                    search.clear();
                    _onSearch('');
                  }),
              const SizedBox(height: 14),
              if (searchingNow)
                ..._searchResults(theme)
              else ...[
                _ShareCard(
                    username: _myUsername,
                    look: widget.look,
                    following: following.length,
                    followers: followers.length,
                    onCopy: _copyUsername),
                const SizedBox(height: 20),
                ..._followBack(theme),
                _SectionLabel('Leaderboard',
                    color: theme.deep,
                    trailing: Text('TOTAL XP',
                        style: display(11.5, color: muted, letterSpacing: 1))),
                ..._leaderboard(theme),
                const SizedBox(height: 20),
                _SectionLabel('Friends’ wins', color: theme.deep),
                ..._feed(theme),
              ],
            ]));
  }

  List<Widget> _searchResults(UnitTheme theme) {
    if (searching && results.isEmpty) {
      return const [
        Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()))
      ];
    }
    if (results.isEmpty) {
      return [
        _EmptyNote(
            emoji: '🔎',
            text: 'No one called “$query” yet. Check the spelling, or ask '
                'your friend for their @username.')
      ];
    }
    return [
      _SectionLabel('People', color: theme.deep),
      for (final p in results)
        Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _PersonRow(
                person: p,
                onTap: () => _showPerson(p),
                trailing: _FollowButton(
                    following: p.youFollow, onTap: () => _toggleFollow(p)))),
    ];
  }

  List<Widget> _followBack(UnitTheme theme) {
    final back = followers.where((p) => !p.youFollow).toList();
    if (back.isEmpty) return const [];
    return [
      _SectionLabel('Follow back', color: theme.deep),
      for (final p in back)
        Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _PersonRow(
                person: p,
                subtitle: 'Follows you',
                onTap: () => _showPerson(p),
                trailing: _FollowButton(
                    following: false,
                    label: 'FOLLOW BACK',
                    onTap: () => _toggleFollow(p)))),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _leaderboard(UnitTheme theme) {
    final rows = <(Person, bool)>[
      for (final p in following) (p, false),
      (
        Person(
            id: 'me',
            name: (widget.me?['name'] ?? 'You').toString(),
            username: _myUsername,
            xp: widget.xp,
            level: levelForXp(widget.xp)),
        true
      ),
    ]..sort((a, b) => b.$1.xp.compareTo(a.$1.xp));
    return [
      for (var i = 0; i < rows.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _CrewRow(
                rank: i + 1,
                name: rows[i].$1.name,
                xp: rows[i].$1.xp,
                look: rows[i].$2
                    ? widget.look
                    : LearnerLook.fromAvatar(rows[i].$1.avatar,
                        seed: rows[i].$1.name),
                me: rows[i].$2,
                theme: theme,
                onTap: rows[i].$2 ? null : () => _showPerson(rows[i].$1))),
      if (loaded && following.isEmpty)
        const _EmptyNote(
            emoji: '👋',
            text: 'Search for friends above and follow them to race up the '
                'leaderboard together.'),
    ];
  }

  List<Widget> _feed(UnitTheme theme) {
    if (!loaded) {
      return const [
        Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()))
      ];
    }
    if (feed.isEmpty) {
      return const [
        _EmptyNote(
            emoji: '🎈',
            text: 'Finished lessons, level-ups and streaks from you and the '
                'people you follow show up here.')
      ];
    }
    return [
      for (final item in feed)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FeedCard(
                item: item,
                theme: theme,
                myLook: widget.look,
                onCheer: () => _cheer(item),
                onActor: item.mine || item.actorUsername.isEmpty
                    ? null
                    : () {
                        final known = [...following, ...followers]
                            .where((p) => p.username == item.actorUsername);
                        _showPerson(known.isNotEmpty
                            ? known.first
                            : Person(
                                id: item.actorUsername,
                                name: item.actorName,
                                username: item.actorUsername,
                                avatar: item.actorAvatar,
                                youFollow: true));
                      })),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller,
      required this.onChanged,
      required this.onClear});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: 2));
    return ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
            controller: controller,
            onChanged: onChanged,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
                hintText: 'Find friends by name or @username',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, color: muted),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, color: muted)),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: border(panel2),
                focusedBorder: border(pink))));
  }
}

/// Your @username, ready to share, with follow counts.
class _ShareCard extends StatelessWidget {
  const _ShareCard(
      {required this.username,
      required this.look,
      required this.following,
      required this.followers,
      required this.onCopy});
  final String username;
  final LearnerLook look;
  final int following, followers;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) => _Slab(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(children: [
        LearnerBadge(look: look, size: 48, radius: 24),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: display(18, weight: FontWeight.w700)),
          Text('$following following · $followers followers',
              style: const TextStyle(
                  color: muted, fontWeight: FontWeight.w800, fontSize: 13)),
        ])),
        _Chunky(
            fill: const Color(0xFFFFEEF3),
            edge: const Color(0xFFF6A9C0),
            radius: 14,
            onTap: onCopy,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.ios_share_rounded, color: pink, size: 18),
                  const SizedBox(width: 6),
                  Text('SHARE', style: display(13.5, color: pink)),
                ]))),
      ]));
}

class _PersonRow extends StatelessWidget {
  const _PersonRow(
      {required this.person,
      required this.onTap,
      required this.trailing,
      this.subtitle});
  final Person person;
  final VoidCallback onTap;
  final Widget trailing;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => _Chunky(
      fill: Colors.white,
      edge: panel2,
      radius: 18,
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(children: [
            LearnerBadge(
                look: LearnerLook.fromAvatar(person.avatar, seed: person.name),
                size: 46,
                radius: 23),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(
                      subtitle ?? '@${person.username} · Level ${person.level}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ])),
            trailing,
          ])));
}

class _FollowButton extends StatelessWidget {
  const _FollowButton(
      {required this.following, required this.onTap, this.label});
  final bool following;
  final VoidCallback onTap;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
      container: true,
      button: true,
      label: following ? 'Following' : (label ?? 'Follow'),
      excludeSemantics: true,
      child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: following ? Colors.white : pink,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: following ? panel2 : pink, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: following ? panel2 : const Color(0xFFB8256F),
                        offset: const Offset(0, 3))
                  ]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    following
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 17,
                    color: following ? muted : Colors.white),
                const SizedBox(width: 5),
                Text(following ? 'FOLLOWING' : (label ?? 'FOLLOW'),
                    style: display(13,
                        color: following ? muted : Colors.white,
                        letterSpacing: .5)),
              ]))));
}

class _CrewRow extends StatelessWidget {
  const _CrewRow(
      {required this.rank,
      required this.name,
      required this.xp,
      required this.look,
      required this.me,
      required this.theme,
      this.onTap});
  final int rank, xp;
  final String name;
  final LearnerLook look;
  final bool me;
  final UnitTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Chunky(
      fill: me ? theme.light : Colors.white,
      edge: me ? theme.glow : panel2,
      radius: 18,
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(children: [
            SizedBox(
                width: 34,
                child: Center(
                    child: rank <= 3
                        ? Text(['🥇', '🥈', '🥉'][rank - 1],
                            style: const TextStyle(fontSize: 24))
                        : Text('$rank',
                            style: display(18,
                                color: muted, weight: FontWeight.w700)))),
            const SizedBox(width: 6),
            LearnerBadge(look: look, size: 42, radius: 21),
            const SizedBox(width: 12),
            Expanded(
                child: Text(me ? '$name (you)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: me ? theme.deep : ink))),
            _XpPill(xp: xp),
          ])));
}

class _XpPill extends StatelessWidget {
  const _XpPill({required this.xp});
  final int xp;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3D1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bolt_rounded, color: Color(0xFFF2A51F), size: 18),
        Text('$xp XP',
            style: const TextStyle(
                color: amberInk, fontWeight: FontWeight.w900, fontSize: 13)),
      ]));
}

/// What a feed item says, with its badge emoji and colour.
({String emoji, Color color, String action}) _describe(FeedItem item) {
  switch (item.type) {
    case 'levelUp':
      return (emoji: '⭐', color: purple, action: 'reached level ${item.level}');
    case 'streak':
      return (
        emoji: '🔥',
        color: orange,
        action: 'hit a ${item.streak}-day streak'
      );
  }
  Lesson? lesson;
  for (final l in lessons) {
    if (l.id == item.lessonId) lesson = l;
  }
  if (lesson != null && lesson.kind == 'assessment') {
    return (
      emoji: '🏆',
      color: sun,
      action: 'passed the final ${lesson.level} test'
    );
  }
  if (lesson != null && lesson.kind == 'checkpoint') {
    return (
      emoji: '🏅',
      color: teal,
      action: 'passed the “${lesson.unitTitle}” checkpoint'
    );
  }
  return (
    emoji: '🎉',
    color: green,
    action: 'finished “${lesson?.title ?? 'a lesson'}”'
  );
}

class _FeedCard extends StatelessWidget {
  const _FeedCard(
      {required this.item,
      required this.theme,
      required this.onCheer,
      required this.myLook,
      this.onActor});
  final FeedItem item;
  final UnitTheme theme;
  final LearnerLook myLook;
  final VoidCallback onCheer;
  final VoidCallback? onActor;

  @override
  Widget build(BuildContext context) {
    final what = _describe(item);
    final name = item.mine ? 'You' : item.actorName;
    return _Slab(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(children: [
          GestureDetector(
              onTap: onActor,
              child: Stack(clipBehavior: Clip.none, children: [
                LearnerBadge(
                    look: item.mine
                        ? myLook
                        : LearnerLook.fromAvatar(item.actorAvatar,
                            seed: item.actorName),
                    size: 48,
                    radius: 24),
                Positioned(
                    right: -6,
                    bottom: -4,
                    child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: what.color,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5)),
                        child: Text(what.emoji,
                            style: const TextStyle(fontSize: 12)))),
              ])),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      TextSpan(text: ' ${what.action}'),
                    ]),
                    style: const TextStyle(fontSize: 15, height: 1.3)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(timeAgo(item.createdAt),
                      style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  if (item.type == 'lesson' && item.xp > 0) ...[
                    const SizedBox(width: 8),
                    _XpPill(xp: item.xp),
                  ],
                ]),
              ])),
          const SizedBox(width: 6),
          _CheerButton(
              cheered: item.liked,
              count: item.likeCount,
              enabled: !item.mine,
              onTap: onCheer),
        ]));
  }
}

/// 👏 that pops when you cheer. Your own posts show the count only.
class _CheerButton extends StatelessWidget {
  const _CheerButton(
      {required this.cheered,
      required this.count,
      required this.enabled,
      required this.onTap});
  final bool cheered, enabled;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      container: true,
      button: enabled,
      label: cheered ? 'Cheered, $count' : 'Cheer, $count',
      excludeSemantics: true,
      child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedScale(
              scale: cheered ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.elasticOut,
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: cheered ? const Color(0xFFFFF0D6) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cheered ? const Color(0xFFF2B33D) : panel2,
                          width: 2)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(
                        opacity: enabled || count > 0 ? 1 : .5,
                        child:
                            const Text('👏', style: TextStyle(fontSize: 18))),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Text('$count',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cheered ? amberInk : muted)),
                    ],
                  ])))));
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.emoji, required this.text});
  final String emoji, text;
  @override
  Widget build(BuildContext context) => _Slab(
          child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: muted, fontWeight: FontWeight.w700, height: 1.35))),
      ]));
}

/// A friend's card: big avatar, level, XP and streak, and follow toggle.
class _PersonSheet extends StatelessWidget {
  const _PersonSheet({required this.person, required this.onToggle});
  final Person person;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final look = LearnerLook.fromAvatar(person.avatar, seed: person.name);
    return Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                  width: 150,
                  height: 160,
                  child: AvatarBackdrop(
                      look: look, child: LearnerPortrait(look: look)))),
          const SizedBox(height: 12),
          Text(person.name,
              textAlign: TextAlign.center,
              style: display(26, weight: FontWeight.w700)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('@${person.username}',
                style:
                    const TextStyle(color: muted, fontWeight: FontWeight.w800)),
            if (person.followsYou) ...[
              const SizedBox(width: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: mint, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Follows you',
                      style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w900,
                          fontSize: 12))),
            ],
          ]),
          const SizedBox(height: 16),
          Row(children: [
            for (final (emoji, value, label) in [
              ('⭐', 'Level ${person.level}', 'Level'),
              ('⚡', '${person.xp}', 'Total XP'),
              ('🔥', '${person.streak}', 'Day streak'),
            ])
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Slab(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 6),
                          child: Column(children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            FittedBox(
                                child: Text(value,
                                    style:
                                        display(17, weight: FontWeight.w700))),
                            Text(label,
                                style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ])))),
          ]),
          const SizedBox(height: 18),
          KButton(
              text: person.youFollow ? 'FOLLOWING ✓' : 'FOLLOW',
              outline: person.youFollow,
              color: pink,
              onTap: onToggle),
        ]));
  }
}
