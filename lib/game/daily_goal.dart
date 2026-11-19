part of '../main.dart';

/// Daily XP goals the learner can pick, with a friendly name for each.
const dailyGoalOptions = <(int, String)>[
  (10, 'Casual'),
  (20, 'Regular'),
  (30, 'Serious'),
  (50, 'Intense'),
];
const defaultDailyGoal = 20;

String _two(int n) => n.toString().padLeft(2, '0');

/// A calendar day as `yyyy-mm-dd`, in local time.
String dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// The local practice diary: today's XP and the days with any practice.
class DailyLog {
  static const goalKey = 'daily.goal',
      dateKey = 'daily.date',
      xpKey = 'daily.xp',
      daysKey = 'activeDays';

  final int goal;
  final String date;
  final int xp;
  final Set<String> days;
  const DailyLog(
      {this.goal = defaultDailyGoal,
      this.date = '',
      this.xp = 0,
      this.days = const {}});

  /// XP earned today; a log from an earlier day counts as zero.
  int xpOn(DateTime now) => date == dayKey(now) ? xp : 0;
  bool activeOn(DateTime now) => days.contains(dayKey(now));

  static DailyLog read(SharedPreferences p) {
    final days = (p.getStringList(daysKey) ?? []).toSet();
    // Learners from before the diary keep their last active day.
    final last = DateTime.tryParse(p.getString('lastActive') ?? '');
    if (days.isEmpty && last != null) days.add(dayKey(last));
    return DailyLog(
        goal: p.getInt(goalKey) ?? defaultDailyGoal,
        date: p.getString(dateKey) ?? '',
        xp: p.getInt(xpKey) ?? 0,
        days: days);
  }

  /// Add [gained] XP for [now], keeping only the last 60 active days.
  DailyLog record(int gained, DateTime now) {
    final today = dayKey(now);
    final kept = ({...days, today}.toList()..sort());
    return DailyLog(
        goal: goal,
        date: today,
        xp: xpOn(now) + gained,
        days: kept.skip(math.max(0, kept.length - 60)).toSet());
  }

  DailyLog withGoal(int value) =>
      DailyLog(goal: value, date: date, xp: xp, days: days);

  Future<void> save(SharedPreferences p) async {
    await p.setInt(goalKey, goal);
    await p.setString(dateKey, date);
    await p.setInt(xpKey, xp);
    await p.setStringList(daysKey, days.toList());
  }

  static Future<void> clear(SharedPreferences p) async {
    await p.remove(dateKey);
    await p.remove(xpKey);
    await p.remove(daysKey);
  }
}

/// A small ring in the header showing today's XP against the goal.
class _DailyGoalChip extends StatelessWidget {
  const _DailyGoalChip(
      {required this.xp, required this.goal, required this.onTap});
  final int xp, goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reached = xp >= goal;
    return Tooltip(
        message: 'Daily goal: $xp / $goal XP',
        child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: TweenAnimationBuilder<double>(
                tween: Tween(end: (xp / goal).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, progress, __) => SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFE1F3EA),
                              color: correctGreen)),
                      Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: reached ? correctGreen : mint),
                          child: reached
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                              : const Text('🎯',
                                  style: TextStyle(fontSize: 15))),
                    ])))));
  }
}

/// The streak chip: a lit flame once you've practised today, a cooled one
/// with a nudge while today's practice is still to do.
class _StreakChip extends StatelessWidget {
  const _StreakChip(
      {required this.streak, required this.safe, required this.onTap});
  final int streak;
  final bool safe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final atRisk = streak > 0 && !safe;
    return _StatChip(
        color: atRisk ? panel2 : peach,
        tooltip: atRisk
            ? 'Practise today to keep your $streak-day streak'
            : '$streak-day streak',
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(Icons.local_fire_department_rounded,
                color: atRisk ? const Color(0xFFA8A3C0) : orange, size: 22),
            if (atRisk)
              Positioned(
                  right: -2,
                  top: -1,
                  child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: red,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5)))),
          ]),
          const SizedBox(width: 2),
          Text('$streak',
              style: display(17,
                  color: atRisk ? muted : amberInk, weight: FontWeight.w700)),
        ]));
  }
}

/// Streak, this week's practice days and the daily goal, in one sheet.
Future<void> showStreakSheet(BuildContext context,
    {required int streak,
    required DailyLog log,
    required Future<void> Function(int) onGoal}) {
  return showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        var goal = log.goal;
        final now = DateTime.now();
        final today = log.xpOn(now);
        final safe = log.activeOn(now);
        final monday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return StatefulBuilder(
            builder: (context, setSheet) => SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Text(streak > 0 && !safe ? '🧊' : '🔥',
                                style: const TextStyle(fontSize: 46)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('$streak-day streak',
                                      style:
                                          display(28, weight: FontWeight.w700)),
                                  Text(
                                      safe
                                          ? 'You practised today. See you tomorrow!'
                                          : streak > 0
                                              ? 'Practise today to keep it going.'
                                              : 'Finish a practice to start a streak.',
                                      style: const TextStyle(
                                          color: muted, fontSize: 14)),
                                ])),
                          ]),
                          const SizedBox(height: 18),
                          Container(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 14, 10, 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: panel2, width: 2)),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    for (var i = 0; i < 7; i++)
                                      _WeekDay(
                                          label: 'MTWTFSS'[i],
                                          active: log.days.contains(dayKey(
                                              monday.add(Duration(days: i)))),
                                          today: i == now.weekday - 1,
                                          future: i > now.weekday - 1),
                                  ])),
                          const SizedBox(height: 20),
                          Row(children: [
                            Text('Daily goal',
                                style: display(20, weight: FontWeight.w600)),
                            const Spacer(),
                            Text('${math.min(today, goal)} / $goal XP',
                                style: const TextStyle(
                                    color: muted, fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 8),
                          _GlossyProgress(
                              value: today / goal, color: correctGreen),
                          const SizedBox(height: 14),
                          Row(children: [
                            for (final (value, name) in dailyGoalOptions)
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: _Chunky(
                                          fill: value == goal
                                              ? mint
                                              : Colors.white,
                                          edge: value == goal
                                              ? correctGreen
                                              : panel2,
                                          onTap: () {
                                            setSheet(() => goal = value);
                                            onGoal(value);
                                          },
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 9),
                                              child: Column(children: [
                                                FittedBox(
                                                    child: Text(name,
                                                        style: display(14,
                                                            color: value == goal
                                                                ? green
                                                                : ink))),
                                                Text('$value XP',
                                                    style: const TextStyle(
                                                        color: muted,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                              ]))))),
                          ]),
                        ]))));
      });
}

class _WeekDay extends StatelessWidget {
  const _WeekDay(
      {required this.label,
      required this.active,
      required this.today,
      required this.future});
  final String label;
  final bool active, today, future;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                color: today ? orange : muted,
                fontWeight: FontWeight.w900,
                fontSize: 12)),
        const SizedBox(height: 6),
        Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFB347), orange])
                    : null,
                color:
                    active ? null : (future ? const Color(0xFFF5F2F9) : panel2),
                border: today
                    ? Border.all(
                        color: active ? const Color(0xFFFFD9B8) : orange,
                        width: 2.5)
                    : null),
            child: active
                ? const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 20)
                : null),
      ]);
}
