part of '../main.dart';

const _cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// The drop-down under the header's flag: courses as big tiles, the
/// learner's level on a glowing bar, and quick ways to keep practising.
class _CoursePanel extends StatefulWidget {
  const _CoursePanel(
      {super.key,
      required this.done,
      required this.completedRounds,
      required this.xp,
      required this.mistakes,
      required this.onChat,
      required this.onMistakes,
      required this.onGoal,
      required this.onClose});
  final Set<String> done, completedRounds;
  final int xp, mistakes;
  final VoidCallback onChat, onGoal, onClose;
  final VoidCallback? onMistakes;

  @override
  State<_CoursePanel> createState() => _CoursePanelState();
}

class _CoursePanelState extends State<_CoursePanel> {
  bool aboutLevel = false;

  @override
  Widget build(BuildContext context) {
    final current = lessons.firstWhere((l) => !widget.done.contains(l.id),
        orElse: () => lessons.isEmpty
            ? Lesson('', '', '', '', '', const [])
            : lessons.last);
    final level = _cefr.contains(current.level) ? current.level : 'A1';
    final inLevel = lessons.where((l) => l.level == level).toList();
    final finished = inLevel.where((l) => widget.done.contains(l.id)).length;
    final progress = inLevel.isEmpty ? 0.0 : finished / inLevel.length;
    final nextLevel = _cefr.indexOf(level) + 1 < _cefr.length
        ? _cefr[_cefr.indexOf(level) + 1]
        : level;
    final practised = {
      ...widget.done,
      ...widget.completedRounds
          .map((key) => key.substring(0, key.lastIndexOf(':'))),
    };
    var wordCount = 0;
    for (var i = 0; i < words.length && i < wordLesson.length; i++) {
      if (practised.contains(wordLesson[i])) wordCount++;
    }
    final totalDone = lessons.where((l) => widget.done.contains(l.id)).length;

    return Container(
        decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                  color: ink.withValues(alpha: .16),
                  blurRadius: 24,
                  offset: const Offset(0, 12))
            ]),
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: 128,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CourseTile(
                            label: 'Serbian',
                            caption: 'From English',
                            selected: true,
                            onTap: widget.onClose,
                            face: const Padding(
                                padding: EdgeInsets.all(12),
                                child: _SerbianFlag(width: 70))),
                        _CourseTile(
                            label: 'Chat',
                            caption: 'With Kristina',
                            color: const Color(0xFF7B5CFA),
                            onTap: widget.onChat,
                            face: const Text('💬',
                                style: TextStyle(fontSize: 38))),
                        _CourseTile(
                            label: 'More soon',
                            caption: 'New languages',
                            dashed: true,
                            onTap: () => ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content:
                                      Text('More languages are on the way!'))),
                            face: const Icon(Icons.add_rounded,
                                size: 40, color: muted)),
                      ])),
              const SizedBox(height: 12),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: panel2, width: 2)),
                      child: Column(children: [
                        Row(children: [
                          _LevelPill(text: level, filled: true),
                          const SizedBox(width: 10),
                          Expanded(child: _GlowBar(value: progress)),
                          const SizedBox(width: 10),
                          _LevelPill(text: nextLevel, filled: false),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              _MiniStat(
                                  emoji: '📘',
                                  text:
                                      '$totalDone / ${lessons.length} lessons'),
                              _MiniStat(emoji: '🧠', text: '$wordCount words'),
                              _MiniStat(emoji: '⚡', text: '${widget.xp} XP'),
                            ]),
                        AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: aboutLevel
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                        'Levels follow the CEFR scale used '
                                        'across Europe, from A1 (beginner) to '
                                        'C2 (mastery). You’re ${(progress * 100).round()}% '
                                        'through $level: finish its lessons '
                                        'and checkpoints to reach $nextLevel.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: muted, height: 1.4)))
                                : const SizedBox(width: double.infinity)),
                        TextButton(
                            onPressed: () =>
                                setState(() => aboutLevel = !aboutLevel),
                            child: Text(
                                aboutLevel ? 'GOT IT' : 'ABOUT YOUR LEVEL',
                                style: display(14,
                                    color: blue, letterSpacing: 1))),
                      ]))),
              const SizedBox(height: 16),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text('Keep practising', style: display(20))),
              const SizedBox(height: 10),
              SizedBox(
                  height: 112,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _PracticeTile(
                            emoji: '💬',
                            label: 'Chat',
                            color: const Color(0xFF3B82F6),
                            onTap: widget.onChat),
                        _PracticeTile(
                            emoji: '🩹',
                            label: 'Mistakes',
                            color: const Color(0xFFEC4899),
                            badge: widget.mistakes > 0
                                ? '${widget.mistakes}'
                                : null,
                            onTap: widget.mistakes >= minMistakeSession
                                ? widget.onMistakes
                                : null),
                        _PracticeTile(
                            emoji: '🎯',
                            label: 'Daily goal',
                            color: const Color(0xFF22A45D),
                            onTap: widget.onGoal),
                      ])),
            ]));
  }
}

/// A big, chunky course tile with a ledge; the current one glows blue.
class _CourseTile extends StatelessWidget {
  const _CourseTile(
      {required this.label,
      required this.caption,
      required this.face,
      required this.onTap,
      this.color = Colors.white,
      this.selected = false,
      this.dashed = false});
  final String label, caption;
  final Widget face;
  final VoidCallback onTap;
  final Color color;
  final bool selected, dashed;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
          button: true,
          selected: selected,
          label: '$label, $caption',
          excludeSemantics: true,
          child: GestureDetector(
              onTap: () {
                learningFeedback.tap(sound: false);
                onTap();
              },
              child: SizedBox(
                  width: 100,
                  child: Column(children: [
                    Container(
                        width: 100,
                        height: 76,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: selected
                                    ? const Color(0xFF4FA8F5)
                                    : Colors.transparent,
                                width: 3),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF4FA8F5)
                                            .withValues(alpha: .35),
                                        blurRadius: 12)
                                  ]
                                : null),
                        child: dashed
                            ? CustomPaint(
                                painter: _DashedBox(),
                                child: Center(child: face))
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border(
                                        left: BorderSide(
                                            color: color == Colors.white
                                                ? panel2
                                                : color,
                                            width: 2),
                                        right: BorderSide(
                                            color: color == Colors.white
                                                ? panel2
                                                : color,
                                            width: 2),
                                        top: BorderSide(
                                            color: color == Colors.white
                                                ? panel2
                                                : color,
                                            width: 2),
                                        bottom: BorderSide(
                                            color: color == Colors.white
                                                ? panel2
                                                : color,
                                            width: 5)),
                                    boxShadow: color == Colors.white
                                        ? null
                                        : [
                                            BoxShadow(
                                                color: Color.lerp(
                                                    color, Colors.black, .25)!,
                                                offset: const Offset(0, 3))
                                          ]),
                                child: Center(child: face))),
                    const SizedBox(height: 6),
                    Text(label,
                        maxLines: 1,
                        style: display(16, color: dashed ? muted : ink)),
                    Text(caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ])))));
}

class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(17)));
    final paint = Paint()
      ..color = const Color(0xFFC9C3D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBox old) => false;
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.text, required this.filled});
  final String text;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: filled ? correctGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filled ? correctGreen : panel2, width: 2)),
      child: Text(text,
          style: display(15,
              color: filled ? Colors.white : muted, weight: FontWeight.w700)));
}

/// A fat lime bar with a glowing sparkle riding its tip.
class _GlowBar extends StatelessWidget {
  const _GlowBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => LayoutBuilder(builder: (context, box) {
            final tip = math.max(18.0, box.maxWidth * t);
            return SizedBox(
                height: 26,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      height: 18,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: const Color(0xFFEDE9F4),
                              borderRadius: BorderRadius.circular(10)))),
                  Positioned(
                      left: 0,
                      width: tip,
                      top: 4,
                      height: 18,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF8FD14F),
                                Color(0xFFD4F25A)
                              ]),
                              borderRadius: BorderRadius.circular(10)),
                          child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                  margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .5),
                                      borderRadius:
                                          BorderRadius.circular(4)))))),
                  Positioned(
                      left: tip - 13,
                      top: 0,
                      child: Container(
                          width: 26,
                          height: 26,
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFFFF27A)
                                    .withValues(alpha: .9),
                                blurRadius: 14,
                                spreadRadius: 2)
                          ]),
                          child: const Icon(Icons.auto_awesome,
                              size: 20, color: Colors.white))),
                ]));
          }));
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.emoji, required this.text});
  final String emoji, text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: muted, fontWeight: FontWeight.w800, fontSize: 13)),
      ]);
}

/// A square, colourful practice shortcut with a big emoji.
class _PracticeTile extends StatelessWidget {
  const _PracticeTile(
      {required this.emoji,
      required this.label,
      required this.color,
      required this.onTap,
      this.badge});
  final String emoji, label;
  final Color color;
  final VoidCallback? onTap;
  final String? badge;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fill = enabled ? color : const Color(0xFFD9D4E4);
    return Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
                onTap: enabled
                    ? () {
                        learningFeedback.tap(sound: false);
                        onTap!();
                      }
                    : null,
                child: SizedBox(
                    width: 84,
                    child: Column(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(
                            width: 84,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Color.lerp(fill, Colors.black, .22)!,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Opacity(
                                opacity: enabled ? 1 : .5,
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 32)))),
                        if (badge != null)
                          Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: red,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white, width: 2)),
                                  child: Text(badge!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900)))),
                      ]),
                      const SizedBox(height: 8),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(15, color: enabled ? ink : muted)),
                    ])))));
  }
}
