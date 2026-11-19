part of '../main.dart';

const _sectionHeaderExtent = 150.0;
const _lessonExtent = 112.0;

/// Horizontal swing of the trail: a gentle S-curve through every unit.
double _swing(int indexInUnit) => math.sin(indexInUnit * math.pi / 4);

enum _NodeState { done, active, open, locked }

/// One stop on the trail: the road to the next stop, a little scenery, the
/// lesson coin, its signpost and, on the current lesson, the tutor.
class _TrailRow extends StatelessWidget {
  const _TrailRow({
    required this.lesson,
    required this.indexInUnit,
    required this.theme,
    required this.state,
    required this.sessions,
    required this.last,
    required this.character,
    required this.onTap,
  });

  final Lesson lesson;
  final int indexInUnit, sessions, character;
  final UnitTheme theme;
  final _NodeState state;
  final bool last;
  final VoidCallback? onTap;

  bool get milestone => lesson.kind != 'challenge';

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final width = box.maxWidth;
        final amplitude = math.min(width * .2, 92.0);
        final swing = _swing(indexInUnit);
        final x = width / 2 + swing * amplitude;
        final nextX = width / 2 + _swing(indexInUnit + 1) * amplitude;
        const y = _lessonExtent * .6;
        final size = milestone ? 82.0 : 70.0;
        final labelLeft = swing > .1;
        final labelWidth = math.min(
            168.0, labelLeft ? x - size / 2 - 26 : width - (x + size / 2) - 26);
        final freeLeft = !labelLeft;
        final room = freeLeft ? x - size / 2 : width - (x + size / 2);
        return Stack(clipBehavior: Clip.none, children: [
          // The road and the scenery sit underneath everything.
          Positioned.fill(
              child: CustomPaint(
                  painter: _RoadPainter(
                      from: Offset(x, y),
                      to: last ? null : Offset(nextX, y + _lessonExtent),
                      walked: state == _NodeState.done,
                      theme: theme,
                      seed: lesson.id.hashCode,
                      sceneryLeft: freeLeft,
                      sceneryRoom: state == _NodeState.active ? 0 : room))),
          if (state == _NodeState.active && room > 66)
            Positioned(
                left: freeLeft ? x - size / 2 - 70 : x + size / 2 + 8,
                top: y - 64,
                child: IgnorePointer(
                    child: ExcludeSemantics(
                        child: AnimatedKristina(
                            width: 62,
                            height: 90,
                            character: character,
                            gaze: Offset(freeLeft ? .6 : -.6, .2))))),
          if (labelWidth > 70)
            Positioned(
                left: labelLeft
                    ? x - size / 2 - 14 - labelWidth
                    : x + size / 2 + 14,
                width: labelWidth,
                top: y - 26,
                height: 52,
                child: Align(
                    alignment: labelLeft
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: _Signpost(
                            lesson: lesson,
                            state: state,
                            sessions: sessions,
                            theme: theme,
                            alignRight: labelLeft)))),
          Positioned(
              left: x - size / 2 - 14,
              top: y - size / 2 - 14,
              width: size + 28,
              height: size + 28,
              child: _TrailNode(
                  lesson: lesson,
                  state: state,
                  sessions: sessions,
                  theme: theme,
                  size: size,
                  milestone: milestone,
                  onTap: onTap)),
        ]);
      });
}

/// The little name card beside each coin.
class _Signpost extends StatelessWidget {
  const _Signpost(
      {required this.lesson,
      required this.state,
      required this.sessions,
      required this.theme,
      required this.alignRight});
  final Lesson lesson;
  final _NodeState state;
  final int sessions;
  final UnitTheme theme;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final locked = state == _NodeState.locked;
    final note = switch (state) {
      _NodeState.done => 'Complete',
      _NodeState.active => sessions == 0 ? 'Up next' : '$sessions of 5',
      _NodeState.open => '$sessions of 5',
      _NodeState.locked => lesson.kind == 'challenge' ? 'Locked' : 'Checkpoint',
    };
    return ExcludeSemantics(
        child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
            decoration: BoxDecoration(
                color: locked ? const Color(0xFFF7F5FA) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: state == _NodeState.active
                        ? theme.main.withValues(alpha: .45)
                        : panel2),
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                            color: theme.deep.withValues(alpha: .10),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: alignRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: locked ? muted : ink,
                          fontSize: 13.5,
                          height: 1.15,
                          fontWeight: FontWeight.w800)),
                  Text(note,
                      maxLines: 1,
                      style: TextStyle(
                          color: locked
                              ? const Color(0xFFA7A1BC)
                              : state == _NodeState.done
                                  ? green
                                  : theme.deep,
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w800)),
                ])));
  }
}

/// A chunky 3D coin: it sinks when pressed, and the current lesson breathes,
/// glows and wears a bouncing START bubble.
class _TrailNode extends StatefulWidget {
  const _TrailNode(
      {required this.lesson,
      required this.state,
      required this.sessions,
      required this.theme,
      required this.size,
      required this.milestone,
      required this.onTap});
  final Lesson lesson;
  final _NodeState state;
  final int sessions;
  final UnitTheme theme;
  final double size;
  final bool milestone;
  final VoidCallback? onTap;

  @override
  State<_TrailNode> createState() => _TrailNodeState();
}

class _TrailNodeState extends State<_TrailNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  bool _down = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_TrailNode old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final calm = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.state == _NodeState.active && !calm) {
      if (!_beat.isAnimating) _beat.repeat();
    } else {
      _beat.stop();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    final size = widget.size;
    final locked = state == _NodeState.locked;
    final (face, ledge) = switch (state) {
      _NodeState.locked => (const Color(0xFFE7E3EF), const Color(0xFFCBC4DA)),
      _NodeState.done when widget.milestone => (sun, const Color(0xFFD99A00)),
      _ => (theme.main, theme.deep),
    };
    const depth = 7.0;
    final sink = _down ? depth - 2 : 0.0;
    final radius = widget.milestone
        ? BorderRadius.circular(size * .32)
        : BorderRadius.circular(size / 2);
    Widget icon = Text(
        widget.milestone && state != _NodeState.locked
            ? '🏆'
            : widget.lesson.icon.isEmpty
                ? '⭐'
                : widget.lesson.icon,
        style: TextStyle(fontSize: size * .42, height: 1));
    if (locked) {
      icon = Opacity(
          opacity: .45,
          child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.33, 0.33, 0.33, 0, 0, //
                0.33, 0.33, 0.33, 0, 0, //
                0.33, 0.33, 0.33, 0, 0, //
                0, 0, 0, 1, 0,
              ]),
              child: icon));
    }
    final coin = SizedBox(
        width: size,
        height: size + depth,
        child: Stack(children: [
          Positioned(
              left: 0,
              right: 0,
              top: depth,
              height: size,
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: ledge, borderRadius: radius))),
          AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: sink,
              height: size,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: RadialGradient(
                          center: const Alignment(-.35, -.45),
                          radius: 1.05,
                          colors: [
                            Color.lerp(face, Colors.white, .32)!,
                            face
                          ])),
                  child: Stack(alignment: Alignment.center, children: [
                    // A soft highlight across the top, like a candy shell.
                    Positioned(
                        top: size * .1,
                        left: size * .2,
                        right: size * .2,
                        height: size * .18,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: locked ? .35 : .28),
                                borderRadius: BorderRadius.circular(size)))),
                    icon,
                    if (locked)
                      Positioned(
                          right: size * .06,
                          bottom: size * .04,
                          child: const _NodeBadge(
                              color: Color(0xFFB9B2CB),
                              icon: Icons.lock_rounded)),
                    if (state == _NodeState.done)
                      Positioned(
                          right: size * .02,
                          bottom: size * .02,
                          child: const _NodeBadge(
                              color: green, icon: Icons.check_rounded)),
                  ]))),
        ]));
    return Semantics(
        button: true,
        enabled: !locked,
        label:
            '${widget.lesson.title}, ${widget.sessions} of 5 sessions complete${locked ? ', locked' : ''}',
        child: GestureDetector(
            onTapDown: locked ? null : (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: locked
                ? null
                : () {
                    learningFeedback.tap();
                    widget.onTap?.call();
                  },
            child: AnimatedBuilder(
                animation: _beat,
                builder: (_, child) {
                  final t = _beat.value;
                  final active = state == _NodeState.active;
                  final breathe =
                      active ? 1 + .035 * math.sin(t * 2 * math.pi) : 1.0;
                  return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (active) ...[
                          // An expanding halo that fades as it grows.
                          Transform.scale(
                              scale: 1 + .45 * t,
                              child: Opacity(
                                  opacity: (1 - t) * .5,
                                  child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                          borderRadius: radius,
                                          border: Border.all(
                                              color: theme.main, width: 4))))),
                          CustomPaint(
                              size: Size.square(size + 24),
                              painter: _SessionRing(widget.sessions, theme.main,
                                  stroke: 6, track: theme.light)),
                        ],
                        Transform.scale(scale: breathe, child: child),
                        if (active)
                          Positioned(
                              top: -27 - 5 * math.sin(t * 2 * math.pi).abs(),
                              child: _StartBubble(
                                  text: widget.sessions == 0
                                      ? 'START'
                                      : 'CONTINUE',
                                  color: theme.deep)),
                      ]);
                },
                child: Padding(
                    padding: const EdgeInsets.only(top: 3), child: coin))));
  }
}

class _NodeBadge extends StatelessWidget {
  const _NodeBadge({required this.color, required this.icon});
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5)),
      child: Icon(icon, size: 13, color: Colors.white));
}

class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: panel2, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: .18),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Text(text,
                style: display(14,
                    color: color, weight: FontWeight.w700, letterSpacing: .8))),
        CustomPaint(size: const Size(14, 7), painter: _BubbleTail()),
      ]));
}

class _BubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -2)
      ..close();
    canvas.drawPath(path, Paint()..color = panel2);
    canvas.drawPath(
        Path()
          ..moveTo(2.5, -2)
          ..lineTo(size.width / 2, size.height - 3)
          ..lineTo(size.width - 2.5, -2)
          ..close(),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubbleTail old) => false;
}

/// The dashed road between two stops, plus hand-painted scenery on the free
/// side: pines, round trees, bushes, flowers and little red-roofed houses.
class _RoadPainter extends CustomPainter {
  const _RoadPainter(
      {required this.from,
      required this.to,
      required this.walked,
      required this.theme,
      required this.seed,
      required this.sceneryLeft,
      required this.sceneryRoom});
  final Offset from;
  final Offset? to;
  final bool walked;
  final UnitTheme theme;
  final int seed;
  final bool sceneryLeft;
  final double sceneryRoom;

  @override
  void paint(Canvas canvas, Size size) {
    final end = to;
    if (end != null) {
      final mid = (from.dy + end.dy) / 2;
      final road = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, mid, end.dx, mid, end.dx, end.dy);
      // A soft wide verge, then the dashes.
      canvas.drawPath(
          road,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 22
            ..strokeCap = StrokeCap.round
            ..color = (walked ? theme.light : const Color(0xFFF3EFF7))
                .withValues(alpha: .9));
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = walked
            ? theme.main.withValues(alpha: .75)
            : const Color(0xFFDAD3E6);
      for (final metric in road.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 20) {
          canvas.drawPath(
              metric.extractPath(d, math.min(d + 9, metric.length)), dash);
        }
      }
    }
    if (sceneryRoom < 56) return;
    final random = math.Random(seed);
    if (random.nextDouble() < .25) return;
    final margin = math.min(sceneryRoom - 30, 60.0);
    final x = sceneryLeft
        ? 14 + random.nextDouble() * (margin - 14).clamp(0, 40)
        : size.width - 14 - random.nextDouble() * (margin - 14).clamp(0, 40);
    final y = from.dy + 6 + random.nextDouble() * 22;
    final scale = .8 + random.nextDouble() * .45;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);
    switch (random.nextInt(5)) {
      case 0:
        _pine(canvas);
        _bush(canvas, 16, 6, .7);
      case 1:
        _roundTree(canvas);
      case 2:
        _house(canvas, theme);
      case 3:
        _bush(canvas, 0, 0, 1);
        _flowers(canvas, theme);
      default:
        _pine(canvas);
        canvas.translate(14, 6);
        canvas.scale(.75);
        _pine(canvas);
    }
    canvas.restore();
  }

  static final _paint = Paint()..isAntiAlias = true;

  void _shadow(Canvas canvas, double w) => canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: w, height: 7),
      _paint..color = const Color(0x1A3A2A60));

  void _pine(Canvas canvas) {
    _shadow(canvas, 26);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2.5, -8, 5, 10), const Radius.circular(2)),
        _paint..color = const Color(0xFFB07A55));
    for (final (top, half, color) in [
      (-40.0, 10.0, const Color(0xFF5DBB79)),
      (-30.0, 13.0, const Color(0xFF4AA867)),
      (-19.0, 15.0, const Color(0xFF3E9A5B)),
    ]) {
      canvas.drawPath(
          Path()
            ..moveTo(0, top)
            ..quadraticBezierTo(half * .3, top + 4, half, top + 16)
            ..quadraticBezierTo(0, top + 19, -half, top + 16)
            ..quadraticBezierTo(-half * .3, top + 4, 0, top)
            ..close(),
          _paint..color = color);
    }
  }

  void _roundTree(Canvas canvas) {
    _shadow(canvas, 30);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -14, 6, 16), const Radius.circular(3)),
        _paint..color = const Color(0xFFB07A55));
    canvas.drawCircle(
        const Offset(0, -26), 15, _paint..color = const Color(0xFF6CC584));
    canvas.drawCircle(
        const Offset(-5, -31), 6, _paint..color = const Color(0xFF8FD69E));
    for (final (dx, dy) in [(6.0, -24.0), (-6.0, -20.0), (2.0, -33.0)]) {
      canvas.drawCircle(
          Offset(dx, dy), 2.2, _paint..color = const Color(0xFFFF6B6B));
    }
  }

  void _bush(Canvas canvas, double dx, double dy, double s) {
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);
    _shadow(canvas, 30);
    for (final (x, y, r, c) in [
      (-8.0, -6.0, 8.0, const Color(0xFF4AA867)),
      (8.0, -6.0, 8.0, const Color(0xFF4AA867)),
      (0.0, -10.0, 10.0, const Color(0xFF5DBB79)),
    ]) {
      canvas.drawCircle(Offset(x, y), r, _paint..color = c);
    }
    canvas.restore();
  }

  void _flowers(Canvas canvas, UnitTheme theme) {
    for (final (x, y, c) in [
      (-14.0, 2.0, sun),
      (14.0, 3.0, theme.main),
      (20.0, -3.0, const Color(0xFFFF8FB1)),
    ]) {
      canvas.drawLine(
          Offset(x, y),
          Offset(x, y - 8),
          _paint
            ..color = const Color(0xFF4AA867)
            ..strokeWidth = 1.6);
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        canvas.drawCircle(Offset(x + 3 * math.cos(a), y - 10 + 3 * math.sin(a)),
            2.2, _paint..color = c);
      }
      canvas.drawCircle(
          Offset(x, y - 10), 1.6, _paint..color = const Color(0xFFFFF4C7));
    }
  }

  void _house(Canvas canvas, UnitTheme theme) {
    _shadow(canvas, 40);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-15, -22, 30, 23), const Radius.circular(3)),
        _paint..color = const Color(0xFFFFF4E4));
    canvas.drawPath(
        Path()
          ..moveTo(-19, -20)
          ..lineTo(0, -37)
          ..lineTo(19, -20)
          ..close(),
        _paint..color = const Color(0xFFE5574B));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -12, 8, 13), const Radius.circular(4)),
        _paint..color = theme.deep);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-12, -17, 6, 6), const Radius.circular(1.5)),
        _paint..color = const Color(0xFF8FD3FF));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, -17, 6, 6), const Radius.circular(1.5)),
        _paint..color = const Color(0xFF8FD3FF));
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.from != from ||
      old.to != to ||
      old.walked != walked ||
      old.theme != theme ||
      old.sceneryRoom != sceneryRoom;
}

/// Unit banner: a glossy gradient card with the unit's number, title,
/// progress and a translucent Belgrade skyline. It pins while its lessons
/// scroll.
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title, level;
  final int index, completed, total;
  final VoidCallback? onJump;
  const _SectionHeaderDelegate(
      {required this.title,
      required this.level,
      required this.index,
      required this.completed,
      required this.total,
      this.onJump});

  @override
  double get minExtent => _sectionHeaderExtent;
  @override
  double get maxExtent => _sectionHeaderExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = unitTheme(index);
    final fraction = total == 0 ? 0.0 : completed / total;
    return ColoredBox(
        color: bg,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: theme.deep.withValues(alpha: .35),
                          offset: const Offset(0, 5)),
                      BoxShadow(
                          color: theme.main.withValues(alpha: .25),
                          blurRadius: 18,
                          offset: const Offset(0, 10)),
                    ]),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: DecoratedBox(
                        decoration: BoxDecoration(gradient: theme.gradient),
                        child: LayoutBuilder(
                            builder: (_, box) => Stack(children: [
                                  // Playful bubbles for depth.
                                  Positioned(
                                      right: -30,
                                      top: -40,
                                      child: _Bubble(size: 130, alpha: .12)),
                                  Positioned(
                                      left: box.maxWidth * .42,
                                      bottom: -46,
                                      child: _Bubble(size: 90, alpha: .10)),
                                  Positioned(
                                      right: 0,
                                      bottom: 0,
                                      width: math.min(210, box.maxWidth * .42),
                                      height: box.maxHeight * .9,
                                      child: const Opacity(
                                          opacity: .3,
                                          child: ColorFiltered(
                                              colorFilter: ColorFilter.mode(
                                                  Colors.white,
                                                  BlendMode.srcIn),
                                              child: CustomPaint(
                                                  painter:
                                                      BelgradePostcard())))),
                                  if (onJump != null)
                                    Positioned(
                                        top: 10,
                                        right: 10,
                                        child: _JumpPill(
                                            color: theme.deep, onTap: onJump!)),
                                  Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          18, 12, box.maxWidth * .3, 14),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('UNIT ${index + 1}  ·  $level',
                                                style: display(12.5,
                                                    color: Colors.white
                                                        .withValues(alpha: .85),
                                                    weight: FontWeight.w600,
                                                    letterSpacing: 1.2)),
                                            const SizedBox(height: 2),
                                            Expanded(
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: SizedBox(
                                                            width: box.maxWidth *
                                                                    .7 -
                                                                18,
                                                            child: Text(title,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: display(26,
                                                                    color: Colors
                                                                        .white,
                                                                    height:
                                                                        1.05,
                                                                    weight: FontWeight
                                                                        .w600)))))),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              SizedBox(
                                                  width: 92,
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      child: LinearProgressIndicator(
                                                          value: fraction,
                                                          minHeight: 8,
                                                          backgroundColor:
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          .28),
                                                          color:
                                                              Colors.white))),
                                              const SizedBox(width: 8),
                                              Text('$completed / $total',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: .92),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ]),
                                          ])),
                                ])))))));
  }

  @override
  bool shouldRebuild(_SectionHeaderDelegate old) =>
      old.title != title ||
      old.level != level ||
      old.index != index ||
      old.completed != completed ||
      old.total != total ||
      (old.onJump == null) != (onJump == null);
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});
  final double size, alpha;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha)));
}

class _JumpPill extends StatelessWidget {
  const _JumpPill({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.fast_forward_rounded, size: 16, color: color),
                const SizedBox(width: 3),
                Text('JUMP HERE',
                    style: display(11.5,
                        color: color,
                        weight: FontWeight.w700,
                        letterSpacing: .6)),
              ]))));
}

/// A rounded pill used in the top bar for the streak and other stats.
class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.child, required this.color, this.onTap, this.tooltip});
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final chip = Material(
        color: color,
        shape: const StadiumBorder(),
        child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: child)));
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
