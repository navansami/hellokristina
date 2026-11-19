part of '../main.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic>? user;
  final int xp, streak;
  final Set<String> done;
  final DailyLog daily;
  final Future<void> Function(int)? onGoal;
  final LearnerLook look;
  final Future<void> Function(LearnerLook) onAvatar;
  final VoidCallback onClose;
  final VoidCallback onFriends;
  final Future<void> Function() onLogout;
  const ProfilePage(
      {super.key,
      required this.user,
      required this.xp,
      required this.streak,
      required this.done,
      this.daily = const DailyLog(),
      this.onGoal,
      required this.look,
      required this.onAvatar,
      required this.onClose,
      required this.onFriends,
      required this.onLogout});

  /// Achievements: emoji, name, how to earn it, and whether it's unlocked.
  List<(String, String, String, bool)> _achievements() {
    final titles = lessons.map((l) => l.unitTitle).toSet();
    final unitDone = titles.any((title) {
      final unit = lessons.where((l) => l.unitTitle == title);
      return unit.isNotEmpty && unit.every((l) => done.contains(l.id));
    });
    var learnedWords = 0;
    for (var i = 0; i < words.length && i < wordLesson.length; i++) {
      if (done.contains(wordLesson[i])) learnedWords++;
    }
    final level = levelForXp(xp);
    return [
      ('👋', 'First hello', 'Finish your first lesson', done.isNotEmpty),
      ('🔥', 'On a roll', 'Reach a 3-day streak', streak >= 3),
      ('📅', 'Week warrior', 'Reach a 7-day streak', streak >= 7),
      ('⭐', '50 XP', 'Earn 50 XP', xp >= 50),
      ('🚀', 'Level 5', 'Reach level 5', level >= 5),
      ('💎', '500 XP', 'Earn 500 XP', xp >= 500),
      ('📚', 'Word collector', 'Learn 50 words', learnedWords >= 50),
      ('🏆', 'Unit champion', 'Finish a whole unit', unitDone),
      (
        '🌍',
        'Halfway there',
        'Finish half the course',
        lessons.isNotEmpty && done.length * 2 >= lessons.length
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final portraitInk = look.backgroundColor.computeLuminance() > .55
        ? const Color(0xFF131F24)
        : Colors.white;
    final created = user?['createdAt'];
    final year = created is String ? DateTime.tryParse(created)?.year : null;
    final name = user?['name'] as String? ?? 'Your name';
    final level = levelForXp(xp);
    final achievements = _achievements();
    final unlocked = achievements.where((a) => a.$4).length;
    final today = daily.xpOn(DateTime.now());
    final violet = unitTheme(1);
    return ListView(padding: EdgeInsets.zero, children: [
      ColoredBox(
          color: look.backgroundColor,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Column(children: [
                SizedBox(
                    height: 48,
                    child: Stack(alignment: Alignment.center, children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 52),
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: display(27,
                                  color: portraitInk,
                                  weight: FontWeight.w700))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              tooltip: 'Close',
                              onPressed: onClose,
                              icon: Icon(Icons.close_rounded,
                                  color: portraitInk))),
                      Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              tooltip: 'Settings',
                              onPressed: () => showFeedbackSettings(context),
                              icon: Icon(Icons.settings_rounded,
                                  color: portraitInk)))
                    ])),
                Text(year == null ? 'Learning Serbian' : 'Learning since $year',
                    style: TextStyle(
                        color: portraitInk.withValues(alpha: .72),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                GestureDetector(
                    onTap: () => _editAvatar(context),
                    child: Semantics(
                        button: true,
                        label: 'Edit avatar',
                        child: SizedBox(
                            width: 260,
                            height: 240,
                            child: LearnerPortrait(look: look))))
              ]))),
      Transform.translate(
          offset: const Offset(0, -36),
          child: DecoratedBox(
              decoration: const BoxDecoration(
                  color: bg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28))),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            user == null
                                ? 'Sign in to save your look'
                                : '@${user!['username']}${year == null ? '' : ' · JOINED $year'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                                fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: _ProfileStat(
                                  icon: Icons.local_fire_department_rounded,
                                  color: orange,
                                  value: '$streak',
                                  label: 'Day streak')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _ProfileStat(
                                  icon: Icons.bolt_rounded,
                                  color: const Color(0xFFF2A51F),
                                  value: '$xp',
                                  label: 'Total XP')),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _ProfileStat(
                                  icon: Icons.workspace_premium_rounded,
                                  color: purple,
                                  value: 'Level $level',
                                  label:
                                      '${xpForLevel(level + 1) - xp} XP to next')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _ProfileStat(
                                  icon: Icons.menu_book_rounded,
                                  color: teal,
                                  value: '${done.length}',
                                  label: 'Lessons done')),
                        ]),
                        const SizedBox(height: 16),
                        _Chunky(
                            fill: Colors.white,
                            edge: panel2,
                            radius: 20,
                            onTap: () => showStreakSheet(context,
                                streak: streak,
                                log: daily,
                                onGoal: onGoal ?? (_) async {}),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(children: [
                                        const Text('🎯',
                                            style: TextStyle(fontSize: 22)),
                                        const SizedBox(width: 8),
                                        Text('Daily goal', style: display(19)),
                                        const Spacer(),
                                        Text(
                                            '${math.min(today, daily.goal)} / ${daily.goal} XP',
                                            style: const TextStyle(
                                                color: muted,
                                                fontWeight: FontWeight.w800)),
                                        const Icon(Icons.chevron_right_rounded,
                                            color: muted),
                                      ]),
                                      const SizedBox(height: 10),
                                      _GlossyProgress(
                                          value: today / daily.goal,
                                          color: correctGreen),
                                    ]))),
                        const SizedBox(height: 12),
                        KButton(
                            text: 'ADD FRIENDS',
                            outline: true,
                            onTap: onFriends),
                        const SizedBox(height: 18),
                        Container(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            decoration: BoxDecoration(
                                gradient: violet.gradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                      color: violet.deep,
                                      offset: const Offset(0, 5))
                                ]),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text('Shape your look',
                                            style: display(25,
                                                color: Colors.white,
                                                weight: FontWeight.w700,
                                                height: 1.05))),
                                    const Text('🎨',
                                        style: TextStyle(fontSize: 32)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Mix skin, hair, glasses, and clothes. It stays on your profile.',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: .9),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 14),
                                  Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                          onTap: () => _editAvatar(context),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 13),
                                              child: Center(
                                                  child: Text('EDIT YOUR LOOK',
                                                      style: display(15,
                                                          color: violet.deep,
                                                          letterSpacing:
                                                              .6))))))
                                ])),
                        const SizedBox(height: 24),
                        _SectionLabel('Achievements',
                            trailing: Text('$unlocked / ${achievements.length}',
                                style: display(14,
                                    color: amberInk, weight: FontWeight.w700))),
                        LayoutBuilder(builder: (context, box) {
                          const gap = 10.0;
                          final cell = (box.maxWidth - 2 * gap) / 3;
                          return Wrap(spacing: gap, runSpacing: gap, children: [
                            for (final (index, a) in achievements.indexed)
                              SizedBox(
                                  width: cell,
                                  child: _AchievementCoin(
                                      emoji: a.$1,
                                      label: a.$2,
                                      hint: a.$3,
                                      unlocked: a.$4,
                                      theme: unitTheme(index))),
                          ]);
                        }),
                        const SizedBox(height: 24),
                        ...[
                          _Slab(
                              child: Row(children: [
                            const Icon(Icons.verified_user_rounded,
                                color: correctGreen),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(user?['email'] ?? '',
                                    style: const TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700)))
                          ])),
                          const SizedBox(height: 12),
                          if (user?['role'] == 'admin') ...[
                            _Chunky(
                                fill: Colors.white,
                                edge: panel2,
                                radius: 20,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminPage(
                                            token: SharedToken.value))),
                                child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(children: [
                                      Icon(Icons.admin_panel_settings_rounded,
                                          color: blue),
                                      SizedBox(width: 12),
                                      Expanded(
                                          child: Text('Course studio',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w900))),
                                      Icon(Icons.chevron_right_rounded)
                                    ]))),
                            const SizedBox(height: 12),
                          ],
                          KButton(
                              text: 'SIGN OUT',
                              outline: true,
                              onTap: () async {
                                final out = await confirmSheet(context,
                                    emoji: '👋',
                                    title: 'Sign out?',
                                    body: 'Your progress is saved to your '
                                        'account. This device will forget it '
                                        'until you sign in again.',
                                    stay: 'STAY SIGNED IN',
                                    leave: 'SIGN OUT');
                                if (out) await onLogout();
                              })
                        ]
                      ]))))
    ]);
  }

  void _editAvatar(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AvatarEditor(look: look, onDone: onAvatar)));
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
  final IconData icon;
  final Color color;
  final String value, label;
  @override
  Widget build(BuildContext context) => _Slab(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      radius: 18,
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: display(21, weight: FontWeight.w700, height: 1.1))),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: muted, fontSize: 12, fontWeight: FontWeight.w800)),
        ])),
      ]));
}

/// A round 3D medal: bright and glossy once earned, grey with a lock before.
class _AchievementCoin extends StatelessWidget {
  const _AchievementCoin(
      {required this.emoji,
      required this.label,
      required this.hint,
      required this.unlocked,
      required this.theme});
  final String emoji, label, hint;
  final bool unlocked;
  final UnitTheme theme;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: unlocked ? '$label: unlocked' : hint,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
          label: '$label, ${unlocked ? 'unlocked' : 'locked. $hint'}',
          excludeSemantics: true,
          child: Column(children: [
            SizedBox(
                width: 66,
                height: 70,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                      top: 5,
                      child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: unlocked
                                  ? theme.deep
                                  : const Color(0xFFD4CFE0)))),
                  Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                              center: const Alignment(-.3, -.5),
                              radius: 1,
                              colors: unlocked
                                  ? [theme.glow, theme.main]
                                  : const [
                                      Color(0xFFF6F4FA),
                                      Color(0xFFE6E2EE)
                                    ])),
                      child: unlocked
                          ? Text(emoji, style: const TextStyle(fontSize: 30))
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                .33, .33, .33, 0, 0, //
                                .33, .33, .33, 0, 0, //
                                .33, .33, .33, 0, 0, //
                                0, 0, 0, .45, 0,
                              ]),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 30)))),
                  Positioned(
                      top: 8,
                      left: 16,
                      child: Container(
                          width: 26,
                          height: 9,
                          decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: unlocked ? .45 : .7),
                              borderRadius: BorderRadius.circular(8)))),
                  if (!unlocked)
                    Positioned(
                        right: -2,
                        bottom: 0,
                        child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: const Color(0xFFA8A3C0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5)),
                            child: const Icon(Icons.lock_rounded,
                                color: Colors.white, size: 13))),
                ])),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: unlocked ? ink : muted)),
          ])));
}
