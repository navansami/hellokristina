part of '../main.dart';

class FriendsPage extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? me;
  final int xp;
  final LearnerLook look;
  const FriendsPage(
      {super.key,
      required this.token,
      this.me,
      this.xp = 0,
      this.look = const LearnerLook()});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<dynamic> friends = [], feed = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant FriendsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      if (widget.token == null) {
        setState(() {
          friends = [];
          feed = [];
        });
      } else {
        load();
      }
    }
  }

  Future<void> load() async {
    if (widget.token == null) return;
    try {
      final h = {'Authorization': 'Bearer ${widget.token}'};
      final responses = await Future.wait([
        http.get(api('/api/social/friends'), headers: h),
        http.get(api('/api/social/feed'), headers: h)
      ]);
      if (mounted)
        setState(() {
          friends = jsonDecode(responses[0].body)['friends'] ?? [];
          feed = jsonDecode(responses[1].body)['items'] ?? [];
        });
    } catch (_) {}
  }

  Future<void> addFriend() async {
    final c = TextEditingController();
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: panel,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text('Find a friend', style: display(24)),
                content: TextField(
                    controller: c,
                    autofocus: true,
                    decoration: _input('Their username')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL')),
                  TextButton(
                      onPressed: () async {
                        try {
                          final r = await http.post(api('/api/social/friends'),
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Content-Type': 'application/json'
                              },
                              body: jsonEncode({'username': c.text}));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(r.statusCode == 200
                                  ? 'Friend added!'
                                  : jsonDecode(r.body)['error'] ??
                                      'Could not add friend')));
                          load();
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('ADD'))
                ]));
  }

  Future<void> like(String id) async {
    try {
      await http.post(api('/api/social/feed'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'itemId': id}));
      load();
    } catch (_) {}
  }

  String _lessonTitle(Object? id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson.title;
    }
    return id?.toString() ?? 'a lesson';
  }

  @override
  Widget build(BuildContext context) {
    final theme = unitTheme(5);
    final signedIn = widget.token != null;
    // Everyone in the crew, you included, ranked by total XP.
    final crew = <({String name, int xp, LearnerLook look, bool me})>[
      for (final f in friends)
        (
          name: (f['name'] ?? '').toString(),
          xp: (f['xp'] as num?)?.toInt() ?? 0,
          look: LearnerLook.fromAvatar(f['avatar'],
              seed: (f['name'] ?? '').toString()),
          me: false
        ),
      if (widget.me != null)
        (
          name: (widget.me!['name'] ?? 'You').toString(),
          xp: widget.xp,
          look: widget.look,
          me: true
        ),
    ]..sort((a, b) => b.xp.compareTo(a.xp));
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _PageHero(
              theme: theme,
              eyebrow: 'Together is better',
              title: 'Friends & feed',
              subtitle: 'Cheer each other on. Lovingly, of course.',
              emoji: '👯',
              child: signedIn
                  ? _HeroButton(
                      label: 'ADD FRIEND',
                      icon: Icons.person_add_alt_1_rounded,
                      color: theme.deep,
                      onTap: addFriend)
                  : null),
          const SizedBox(height: 20),
          if (!signedIn)
            const _Slab(
                child: Row(children: [
              Text('🔐', style: TextStyle(fontSize: 32)),
              SizedBox(width: 14),
              Expanded(
                  child: Text(
                      'Create an account from Profile to add friends and share your wins.',
                      style: TextStyle(
                          color: muted, fontWeight: FontWeight.w700))),
            ]))
          else ...[
            _SectionLabel('Your crew',
                color: theme.deep,
                trailing: Text('BY TOTAL XP',
                    style: display(11.5, color: muted, letterSpacing: 1))),
            for (var i = 0; i < crew.length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CrewRow(
                      rank: i + 1,
                      name: crew[i].name,
                      xp: crew[i].xp,
                      look: crew[i].look,
                      me: crew[i].me,
                      theme: theme)),
            if (friends.isEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: _Chunky(
                      fill: theme.light,
                      edge: theme.glow,
                      radius: 18,
                      onTap: addFriend,
                      child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Icon(Icons.group_add_rounded,
                                color: theme.deep, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    'Your crew starts with one friend. Invite someone by username.',
                                    style: TextStyle(
                                        color: theme.deep,
                                        fontWeight: FontWeight.w700))),
                          ])))),
            const SizedBox(height: 18),
            _SectionLabel('Latest wins', color: theme.deep),
            if (feed.isEmpty)
              const _Slab(
                  child: Row(children: [
                Text('🎈', style: TextStyle(fontSize: 30)),
                SizedBox(width: 14),
                Expanded(
                    child: Text(
                        'The feed is quiet. Finish a lesson and make some noise!',
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w700))),
              ]))
            else
              for (final f in feed)
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Slab(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                        child: Row(children: [
                          LearnerBadge(
                              look: LearnerLook.fromAvatar(f['actorAvatar'],
                                  seed: (f['actorName'] ?? '').toString()),
                              size: 46,
                              radius: 23),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: '${f['actorName'] ?? 'A learner'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900)),
                                  const TextSpan(text: ' finished '),
                                  TextSpan(
                                      text: _lessonTitle(f['lessonId']),
                                      style: TextStyle(
                                          color: theme.deep,
                                          fontWeight: FontWeight.w900)),
                                  const TextSpan(text: ' 🎉'),
                                ])),
                                const SizedBox(height: 6),
                                _XpPill(xp: (f['xp'] as num?)?.toInt() ?? 0),
                              ])),
                          Column(children: [
                            IconButton(
                                tooltip: 'Like',
                                onPressed: () => like(f['id']),
                                icon: Icon(
                                    f['liked'] == true
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: pink,
                                    size: 28)),
                            Text('${f['likeCount'] ?? 0}',
                                style: const TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ]),
                        ]))),
          ],
        ]);
  }
}

class _CrewRow extends StatelessWidget {
  const _CrewRow(
      {required this.rank,
      required this.name,
      required this.xp,
      required this.look,
      required this.me,
      required this.theme});
  final int rank, xp;
  final String name;
  final LearnerLook look;
  final bool me;
  final UnitTheme theme;

  @override
  Widget build(BuildContext context) => _Slab(
      fill: me ? theme.light : Colors.white,
      edge: me ? theme.glow : panel2,
      radius: 18,
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
      ]));
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

/// A white pill button that sits on a coloured hero banner.
class _HeroButton extends StatelessWidget {
  const _HeroButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label,
                    style: display(14.5, color: color, letterSpacing: .6)),
              ]))));
}
