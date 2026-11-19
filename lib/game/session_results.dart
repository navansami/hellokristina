part of '../main.dart';

/// The end-of-session celebration: XP counts up, bonuses pop in, the level
/// bar fills and a level-up gets its own fanfare and dance.
class _SessionResults extends StatefulWidget {
  const _SessionResults(
      {required this.title,
      required this.subtitle,
      required this.answers,
      required this.reward,
      required this.startXp,
      required this.character,
      required this.button,
      this.segments = 0,
      this.dailyBefore = 0,
      this.dailyGoal = 0});

  final String title, subtitle;
  final List<bool> answers;
  final SessionReward reward;
  final int startXp, character, segments;

  /// Today's XP before this session and the daily goal (0 hides the goal).
  final int dailyBefore, dailyGoal;
  final Widget button;

  @override
  State<_SessionResults> createState() => _SessionResultsState();
}

class _SessionResultsState extends State<_SessionResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000));
  int _shownXp = 0;
  bool _leveled = false;
  Timer? _ticks;

  int get _endXp => widget.startXp + widget.reward.total;
  int get _startLevel => levelForXp(widget.startXp);
  int get _endLevel => levelForXp(_endXp);
  bool get _levelUp => _endLevel > _startLevel;
  bool get _goalHit =>
      widget.dailyGoal > 0 &&
      widget.dailyBefore < widget.dailyGoal &&
      widget.dailyBefore + widget.reward.total >= widget.dailyGoal;

  // Timeline, as fractions of the controller.
  static const _countFrom = .12, _countTo = .45, _barFrom = .5, _barTo = .8;

  @override
  void initState() {
    super.initState();
    _show.addListener(_onFrame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _show.value = 1;
      _shownXp = widget.reward.total;
      _leveled = _levelUp;
    } else if (!_show.isAnimating && _show.value == 0) {
      _show.forward();
    }
  }

  void _onFrame() {
    final count = Curves.easeOutCubic.transform(
        ((_show.value - _countFrom) / (_countTo - _countFrom)).clamp(0.0, 1.0));
    final xp = (widget.reward.total * count).round();
    if (xp != _shownXp) {
      setState(() => _shownXp = xp);
      // Throttle ticks so a big total still sounds like a counter.
      if (_ticks == null || !_ticks!.isActive) {
        learningFeedback.xpTick();
        _ticks = Timer(const Duration(milliseconds: 55), () {});
      }
    }
    if (_levelUp && !_leveled && _show.value >= _barTo) {
      setState(() => _leveled = true);
      learningFeedback.levelUp();
    }
  }

  @override
  void dispose() {
    _ticks?.cancel();
    _show.dispose();
    super.dispose();
  }

  double _pop(double from, [double length = .12]) => Curves.elasticOut
      .transform(((_show.value - from) / length).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final correct = widget.answers.where((x) => x).length;
    final accuracy = widget.answers.isEmpty
        ? 0
        : (correct * 100 / widget.answers.length).round();
    final perfect = reward.passed && correct == widget.answers.length;
    final mood = _leveled || perfect
        ? 'hot'
        : reward.passed
            ? 'celebrate'
            : 'sad';
    return AnimatedBuilder(
        animation: _show,
        builder: (context, _) => LayoutBuilder(builder: (context, space) {
              final compact = space.maxHeight < 520;
              return Stack(children: [
                Column(children: [
                  SizedBox(height: compact ? 4 : 10),
                  Transform.scale(
                      scale: .4 + .6 * _pop(0, .2),
                      child: Text(widget.title,
                          textAlign: TextAlign.center,
                          style: display(compact ? 27 : 32,
                              weight: FontWeight.w700,
                              color: reward.passed ? ink : red))),
                  Text(widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          color: muted,
                          fontWeight: FontWeight.w700)),
                  Expanded(
                      child: Stack(alignment: Alignment.center, children: [
                    if (reward.passed)
                      Positioned.fill(
                          child: CustomPaint(
                              painter: _SunburstPainter(
                                  turn: _show.value * .6,
                                  strength: _pop(.02, .3).clamp(0.0, 1.0),
                                  hot: _leveled))),
                    AnimatedKristina(
                        width: 200,
                        height: space.maxHeight * .4,
                        character: widget.character,
                        gaze: Offset.zero,
                        mood: mood),
                    if (_leveled)
                      Positioned(
                          top: 4,
                          child: Transform.scale(
                              scale: Curves.elasticOut.transform(
                                  ((_show.value - _barTo) / .15)
                                      .clamp(0.0, 1.0)),
                              child: _LevelUpBanner(level: _endLevel))),
                    if (_goalHit)
                      Positioned(
                          bottom: 4,
                          child: Transform.scale(
                              scale: Curves.elasticOut.transform(
                                  ((_show.value - .84) / .14).clamp(0.0, 1.0)),
                              child: const _GoalBanner())),
                  ])),
                  Row(children: [
                    Expanded(
                        child: _ResultTile(
                            label: 'TOTAL XP',
                            value: '+$_shownXp',
                            icon: Icons.bolt_rounded,
                            color: orange,
                            pop: _pop(.08))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _ResultTile(
                            label: 'ACCURACY',
                            value: '$accuracy%',
                            icon: Icons.track_changes_rounded,
                            color: const Color(0xFF3FA66B),
                            pop: _pop(.16))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _ResultTile(
                            label: 'BEST RUN',
                            value: '×${bestRun(widget.answers)}',
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFE5634D),
                            pop: _pop(.24))),
                  ]),
                  SizedBox(height: compact ? 6 : 10),
                  _BonusLine(
                      reward: reward,
                      show: _show.value,
                      segments: widget.segments),
                  SizedBox(height: compact ? 6 : 10),
                  _LevelBar(
                      startXp: widget.startXp,
                      endXp: _endXp,
                      t: Curves.easeInOutCubic.transform(
                          ((_show.value - _barFrom) / (_barTo - _barFrom))
                              .clamp(0.0, 1.0))),
                  SizedBox(height: compact ? 10 : 16),
                  widget.button,
                  SizedBox(height: compact ? 6 : 12),
                ]),
                if (reward.passed)
                  Positioned.fill(
                      child: IgnorePointer(
                          child: CustomPaint(
                              painter: _ConfettiPainter(
                                  t: _show.value, seed: widget.title.length)))),
              ]);
            }));
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.pop});
  final String label, value;
  final IconData icon;
  final Color color;
  final double pop;

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: pop.clamp(0.0, 1.0),
      child: Transform.scale(
          scale: .6 + .4 * pop,
          child: Container(
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Color.lerp(color, Colors.black, .25)!,
                        offset: const Offset(0, 4))
                  ]),
              padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FittedBox(
                    child: Text(label,
                        style: display(12,
                            color: Colors.white, letterSpacing: .8))),
                const SizedBox(height: 4),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13)),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, color: color, size: 22),
                          const SizedBox(width: 3),
                          Text(value,
                              style: display(22,
                                  color: Color.lerp(color, Colors.black, .35)!,
                                  weight: FontWeight.w700)),
                        ]))),
              ]))));
}

class _BonusLine extends StatelessWidget {
  const _BonusLine(
      {required this.reward, required this.show, this.segments = 0});
  final SessionReward reward;
  final double show;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, Color)>[
      if (segments > 1) ('Ring +$segments', orange),
      if (reward.completion > 0) ('Finish +${reward.completion}', blue),
      ('Answers +${reward.accuracy}', green),
      if (reward.perfect > 0) ('Perfect +${reward.perfect}', purple),
      if (reward.combo > 0) ('Run of 5 +${reward.combo}', red),
      if (reward.passed && !reward.firstTime) ('Replay ×½', muted),
    ];
    return SizedBox(
        height: 24,
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < chips.length; i++)
                Opacity(
                    opacity: ((show - .14 - i * .05) / .08).clamp(0.0, 1.0),
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: chips[i].$2.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(chips[i].$1,
                            style: TextStyle(
                                color: chips[i].$2,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)))),
            ])));
  }
}

/// Fills from the starting XP to the new total, rolling over at each level.
class _LevelBar extends StatelessWidget {
  const _LevelBar(
      {required this.startXp, required this.endXp, required this.t});
  final int startXp, endXp;
  final double t;

  @override
  Widget build(BuildContext context) {
    final xp = (startXp + (endXp - startXp) * t).round();
    final level = levelForXp(xp);
    final next = xpForLevel(level + 1);
    final fraction = levelProgress(xp);
    return Row(children: [
      _LevelMedal(level: level, size: 38),
      const SizedBox(width: 10),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Row(children: [
              Text('Level $level', style: display(16, weight: FontWeight.w700)),
              const Spacer(),
              Text('$xp / $next XP',
                  style: const TextStyle(
                      color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 5),
            _XpBar(fraction: fraction, height: 12),
          ])),
    ]);
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.fraction, this.height = 10});
  final double fraction, height;

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFFEDF0F1)),
            FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFC84A), orange]),
                        borderRadius: BorderRadius.circular(height)),
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                            margin: EdgeInsets.fromLTRB(
                                height * .6, height * .2, height * .6, 0),
                            height: height * .28,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .45),
                                borderRadius:
                                    BorderRadius.circular(height)))))),
          ])));
}

/// A round level medal used in the header, profile and results.
class _LevelMedal extends StatelessWidget {
  const _LevelMedal({required this.level, this.size = 34});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD66B), Color(0xFFF29A2E)]),
          border: Border.all(color: const Color(0xFFFFF3D1), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33F29A2E), blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: Text('$level',
          style: TextStyle(
              color: amberInk,
              fontWeight: FontWeight.w900,
              fontSize: size * .42)));
}

class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF8E5CF0), Color(0xFFE2559A)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
                color: Color(0x558E5CF0), blurRadius: 14, offset: Offset(0, 4))
          ]),
      child: Text('LEVEL UP!  Level $level',
          style: display(17, color: Colors.white, letterSpacing: .8)));
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter(
      {required this.turn, required this.strength, required this.hot});
  final double turn, strength;
  final bool hot;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final center = Offset(size.width / 2, size.height * .5);
    final radius = math.max(size.width, size.height) * .75;
    final paint = Paint()
      ..color = (hot ? const Color(0xFFB98CF5) : const Color(0xFFFFD66B))
          .withValues(alpha: .22 * strength);
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = turn * math.pi + i * 2 * math.pi / rays;
      canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy)
            ..lineTo(center.dx + math.cos(a - .12) * radius,
                center.dy + math.sin(a - .12) * radius)
            ..lineTo(center.dx + math.cos(a + .12) * radius,
                center.dy + math.sin(a + .12) * radius)
            ..close(),
          paint);
    }
    canvas.drawCircle(
        center,
        size.height * .3,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: .9 * strength),
            Colors.white.withValues(alpha: 0)
          ]).createShader(
              Rect.fromCircle(center: center, radius: size.height * .3)));
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) =>
      old.turn != turn || old.strength != strength || old.hot != hot;
}

/// Header level medal with a ring for progress to the next level.
class _HeaderLevel extends StatelessWidget {
  const _HeaderLevel({required this.xp});
  final int xp;

  void _explain(BuildContext context) {
    final level = levelForXp(xp);
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: panel,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _LevelMedal(level: level, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Level $level',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              Text(
                                  '${xpForLevel(level + 1) - xp} XP to level ${level + 1}',
                                  style: const TextStyle(color: muted)),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      _XpBar(fraction: levelProgress(xp), height: 14),
                      const SizedBox(height: 18),
                      const Text('How you earn XP',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text(
                          'Finish a practice  +10\n'
                          'Each correct answer  +2\n'
                          'Perfect practice  +5\n'
                          'Five in a row  +5\n'
                          'Replaying a practice earns half. A practice you '
                          'don’t pass still earns 1 XP per correct answer.',
                          style: TextStyle(color: muted, height: 1.5)),
                    ]))));
  }

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    return Tooltip(
        message: 'Level $level · $xp XP',
        child: InkWell(
            onTap: () => _explain(context),
            customBorder: const CircleBorder(),
            child: TweenAnimationBuilder<double>(
                tween: Tween(end: levelProgress(xp)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, progress, child) => SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              backgroundColor: const Color(0xFFF1E4CC),
                              color: orange)),
                      child!,
                    ])),
                child: _LevelMedal(level: level, size: 30))));
  }
}

/// "Daily goal reached!" popping up under the tutor.
class _GoalBanner extends StatelessWidget {
  const _GoalBanner();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 16, 7),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2CC07E), Color(0xFF13945E)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0B6B43), offset: Offset(0, 3)),
            BoxShadow(
                color: Color(0x5513945E), blurRadius: 14, offset: Offset(0, 6))
          ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎯', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text('Daily goal reached!',
            style: display(16, color: Colors.white, letterSpacing: .3)),
      ]));
}

/// A burst of confetti that falls, sways and fades over the results.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.seed});
  final double t;
  final int seed;

  static const _colors = [
    Color(0xFFFF6B4A),
    Color(0xFF7B5CFA),
    Color(0xFF14B39C),
    Color(0xFF3B82F6),
    Color(0xFFFFC62E),
    Color(0xFFEC4899),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Pieces fly between 2% and 85% of the timeline, then are gone.
    final life = ((t - .02) / .83);
    if (life <= 0 || life >= 1) return;
    final random = math.Random(seed);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final delay = random.nextDouble() * .25;
      final local = ((life - delay) / (1 - delay)).clamp(0.0, 1.0);
      final startX = size.width * (.1 + .8 * random.nextDouble());
      final drift = (random.nextDouble() - .5) * size.width * .5;
      final sway = 10 + random.nextDouble() * 18;
      final spin = (random.nextDouble() - .5) * 14;
      final launch = -.35 - random.nextDouble() * .45;
      final w = 6 + random.nextDouble() * 6, h = 4 + random.nextDouble() * 5;
      final color = _colors[i % _colors.length];
      final round = random.nextBool();
      if (local <= 0) continue;
      // A short upward pop, then gravity takes over.
      final y = size.height * (.32 + launch * local + 1.6 * local * local);
      final x =
          startX + drift * local + math.sin(local * math.pi * 3 + i) * sway;
      final fade = local > .75 ? 1 - (local - .75) / .25 : 1.0;
      paint.color = color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * local);
      // Flip on the X axis so pieces flutter.
      canvas.scale(1, math.cos(local * 12 + i).abs() * .8 + .2);
      if (round) {
        canvas.drawCircle(Offset.zero, w / 2.4, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: w, height: h),
                const Radius.circular(1.5)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
