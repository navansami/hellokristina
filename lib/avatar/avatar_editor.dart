import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'learner_look.dart';
import 'learner_portrait.dart';

import '../feedback/learning_feedback.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/course_palette.dart';
import '../widgets/tactile_button.dart';

/// One editable piece: a style list (shown as mini previews) or a palette.
class _Part {
  final String title, key, kind;
  final List<String>? styles;
  final List<Color>? colors;

  /// Style previews show the head, the whole bust, or the backdrop.
  final _Preview preview;
  const _Part.styles(this.title, this.key, this.kind, List<String> this.styles,
      {this.preview = _Preview.head})
      : colors = null;
  const _Part.colors(this.title, this.key, this.kind, List<Color> this.colors)
      : styles = null,
        preview = _Preview.head;
  int get count => styles?.length ?? colors!.length;
}

enum _Preview { head, bust, backdrop }

class _Tab {
  final String emoji, name;
  final Color color;
  final List<_Part> parts;
  const _Tab(this.emoji, this.name, this.color, this.parts);
}

const _tabs = [
  _Tab('😊', 'Face', Color(0xFFFF6B4A), [
    _Part.colors('Skin tone', 'skin', 'Skin tone', LearnerLook.skins),
    _Part.styles('Face shape', 'face', 'Face shape', LearnerLook.faceShapes),
    _Part.styles('Cheeks', 'cheeks', 'Cheeks', LearnerLook.cheekStyles),
  ]),
  _Tab('👀', 'Eyes', Color(0xFF7B5CFA), [
    _Part.styles('Eyes', 'eyes', 'Eyes', LearnerLook.eyeStyles),
    _Part.colors('Eye colour', 'eyeColor', 'Eye colour', LearnerLook.eyeColors),
    _Part.styles('Lashes', 'lashes', 'Lashes', LearnerLook.lashStyles),
    _Part.styles('Eyebrows', 'brows', 'Eyebrows', LearnerLook.browStyles),
  ]),
  _Tab('👄', 'Mouth', Color(0xFFEC4899), [
    _Part.styles('Mouth', 'mouth', 'Mouth', LearnerLook.mouthStyles),
  ]),
  _Tab('💄', 'Make-up', Color(0xFFE5484D), [
    _Part.styles('Lip colour', 'lips', 'Lip colour', LearnerLook.lipStyles),
    _Part.styles(
        'Eyeshadow', 'eyeshadow', 'Eyeshadow', LearnerLook.eyeshadowStyles),
    _Part.styles('Cheeks', 'cheeks', 'Blush', LearnerLook.cheekStyles),
  ]),
  _Tab('💇', 'Hair', Color(0xFFFF9F1C), [
    _Part.styles('Hairstyle', 'hair', 'Hairstyle', LearnerLook.hairStyles),
    _Part.colors(
        'Hair colour', 'hairColor', 'Hair colour', LearnerLook.hairColors),
    _Part.styles('Facial hair', 'facialHair', 'Facial hair',
        LearnerLook.facialHairStyles),
  ]),
  _Tab('🕶️', 'Extras', Color(0xFF14B39C), [
    _Part.styles('Glasses', 'glasses', 'Glasses', LearnerLook.glassesStyles),
    _Part.colors('Glasses colour', 'glassesColor', 'Glasses colour',
        LearnerLook.glassesColors),
    _Part.styles('Earrings', 'earrings', 'Earrings', LearnerLook.earringStyles),
    _Part.styles('Hair accessory', 'accessory', 'Hair accessory',
        LearnerLook.accessoryStyles),
    _Part.colors('Accessory colour', 'accessoryColor', 'Accessory colour',
        LearnerLook.accessoryColors),
  ]),
  _Tab('👑', 'Hats', Color(0xFF3B82F6), [
    _Part.styles('Headwear', 'hat', 'Headwear', LearnerLook.hatStyles),
    _Part.colors('Headwear colour', 'hatColor', 'Headwear colour',
        LearnerLook.hatColors),
  ]),
  _Tab('👕', 'Outfit', Color(0xFF22A45D), [
    _Part.styles('Outfit', 'outfit', 'Outfit', LearnerLook.outfitStyles,
        preview: _Preview.bust),
    _Part.colors('Outfit colour', 'outfitColor', 'Outfit colour',
        LearnerLook.outfitColors),
    _Part.styles('Pattern', 'pattern', 'Pattern', LearnerLook.patterns,
        preview: _Preview.bust),
  ]),
  _Tab('🖼️', 'Background', Color(0xFFA855F7), [
    _Part.colors('Background colour', 'background', 'Background colour',
        LearnerLook.backgrounds),
    _Part.styles('Backdrop', 'backdrop', 'Backdrop', LearnerLook.backdrops,
        preview: _Preview.backdrop),
  ]),
];

/// Picking a colour for a piece that's switched off switches it on.
const _turnOn = {
  'glassesColor': ('glasses', 1),
  'hatColor': ('hat', 1),
  'accessoryColor': ('accessory', 1),
};

class AvatarEditor extends StatefulWidget {
  final LearnerLook look;
  final Future<void> Function(LearnerLook look) onDone;
  const AvatarEditor({super.key, required this.look, required this.onDone});

  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  late LearnerLook draft = widget.look;
  final List<LearnerLook> history = [];
  int tab = 0, bump = 0, rolls = 0;
  bool saving = false;
  final _random = math.Random();

  void _apply(LearnerLook next) {
    if (next == draft) return;
    learningFeedback.tap();
    setState(() {
      history.add(draft);
      if (history.length > 40) history.removeAt(0);
      draft = next;
      bump++;
    });
  }

  void _set(String key, int value) {
    var next = draft.withValue(key, value);
    final dependent = _turnOn[key];
    if (dependent != null && next.valueOf(dependent.$1) == 0) {
      next = next.withValue(dependent.$1, dependent.$2);
    }
    _apply(next);
  }

  void _surprise() {
    setState(() => rolls++);
    _apply(LearnerLook.random(_random));
  }

  void _undo() {
    if (history.isEmpty) return;
    learningFeedback.tap();
    setState(() {
      draft = history.removeLast();
      bump++;
    });
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.onDone(draft);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Leaving with unsaved changes asks first.
  Future<void> _askToDiscard() async {
    final discard = await confirmSheet(context,
        emoji: '🎨',
        title: 'Discard your changes?',
        body: 'Your new look hasn’t been saved yet.',
        stay: 'KEEP EDITING',
        leave: 'DISCARD CHANGES');
    if (discard && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = _tabs[tab];
    return PopScope(
        canPop: saving || draft == widget.look,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _askToDiscard();
        },
        child: Scaffold(
            backgroundColor: bg,
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: LayoutBuilder(builder: (context, box) {
                          final preview =
                              (box.maxHeight * .34).clamp(180.0, 320.0);
                          return Column(children: [
                            _topBar(),
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 10),
                                child: _previewCard(preview)),
                            _tabBar(),
                            Expanded(
                                child: ListView(
                                    key: PageStorageKey('avatar-tab-$tab'),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 14, 16, 20),
                                    children: [
                                  for (final part in current.parts) ...[
                                    _section(part, current.color),
                                    const SizedBox(height: 22),
                                  ]
                                ])),
                            _saveBar(),
                          ]);
                        }))))));
  }

  Widget _topBar() => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(children: [
        IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close_rounded, color: ink)),
        Expanded(
            child: Text('Create your look',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(22, weight: FontWeight.w700))),
        IconButton(
            tooltip: 'Undo',
            onPressed: history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded)),
      ]));

  Widget _previewCard(double height) => SizedBox(
      height: height,
      child: Stack(children: [
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: _darker(draft.backgroundColor),
                          offset: const Offset(0, 5)),
                    ]),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: AvatarBackdrop(
                            key: ValueKey(
                                '${draft.background}-${draft.backdrop}'),
                            look: draft))))),
        Positioned.fill(
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _LivePortrait(look: draft, bump: bump))),
        Positioned(
            right: 12,
            bottom: 12,
            child: Semantics(
                button: true,
                label: 'Surprise me',
                child: GestureDetector(
                    onTap: _surprise,
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33221C3F),
                                  offset: Offset(0, 3))
                            ]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedRotation(
                              turns: rolls * .75,
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutBack,
                              child: const Text('🎲',
                                  style: TextStyle(fontSize: 22))),
                          const SizedBox(width: 6),
                          Text('Surprise me',
                              style: display(15, color: purple)),
                        ]))))),
      ]));

  Widget _tabBar() => SizedBox(
      height: 52,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final t = _tabs[index];
            final selected = index == tab;
            return Semantics(
                button: true,
                selected: selected,
                label: t.name,
                excludeSemantics: true,
                child: GestureDetector(
                    onTap: () {
                      learningFeedback.tap(sound: false);
                      setState(() => tab = index);
                    },
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(
                            top: selected ? 2 : 0, bottom: selected ? 0 : 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: selected ? t.color : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: selected ? t.color : panel2, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: selected ? _darker(t.color) : panel2,
                                  offset: Offset(0, selected ? 2 : 4))
                            ]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(t.name,
                              style: display(15,
                                  color: selected ? Colors.white : ink)),
                        ]))));
          }));

  Widget _section(_Part part, Color accent) {
    final selected = draft.valueOf(part.key);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(part.title, style: display(19)),
        const Spacer(),
        if (part.styles != null)
          Text(part.styles![selected],
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
      const SizedBox(height: 10),
      if (part.colors != null)
        _swatches(part, selected, accent)
      else
        _styleGrid(part, selected, accent),
    ]);
  }

  Widget _swatches(_Part part, int selected, Color accent) =>
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < part.count; i++)
          Semantics(
              button: true,
              selected: i == selected,
              label: '${part.kind} ${i + 1}',
              excludeSemantics: true,
              child: GestureDetector(
                  onTap: () => _set(part.key, i),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  i == selected ? accent : Colors.transparent,
                              width: 3)),
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                  center: const Alignment(-.35, -.4),
                                  colors: [
                                    Color.lerp(
                                        part.colors![i], Colors.white, .3)!,
                                    part.colors![i],
                                  ]),
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: .08)),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x22000000),
                                    offset: Offset(0, 2))
                              ]),
                          child: i == selected
                              ? Icon(Icons.check_rounded,
                                  size: 20,
                                  color: part.colors![i].computeLuminance() > .6
                                      ? ink
                                      : Colors.white)
                              : null)))),
      ]);

  Widget _styleGrid(_Part part, int selected, Color accent) =>
      LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth > 480 ? 4 : 3;
        const gap = 10.0;
        final cell = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (var i = 0; i < part.count; i++)
            SizedBox(
                width: cell,
                child: _StyleTile(
                    label: part.styles![i],
                    semantics: '${part.kind} ${i + 1}',
                    selected: i == selected,
                    accent: accent,
                    onTap: () => _set(part.key, i),
                    child: _tilePreview(part, i))),
        ]);
      });

  Widget _tilePreview(_Part part, int index) {
    final look = draft.withValue(part.key, index);
    switch (part.preview) {
      case _Preview.backdrop:
        return AvatarBackdrop(
            look: look, child: LearnerPortrait(look: look, headOnly: true));
      case _Preview.bust:
        return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LearnerPortrait(look: look));
      case _Preview.head:
        return Padding(
            padding: const EdgeInsets.all(4),
            child: LearnerPortrait(look: look, headOnly: true));
    }
  }

  Widget _saveBar() => Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(color: bg, boxShadow: [
        BoxShadow(
            color: ink.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, -4))
      ]),
      child: TactileButton(
          label: saving ? 'SAVING…' : 'SAVE MY LOOK',
          color: const Color(0xFF16A36A),
          foreground: Colors.white,
          onTap: saving ? null : _save));
}

Color _darker(Color c) => Color.lerp(c, Colors.black, .2)!;

class _StyleTile extends StatelessWidget {
  const _StyleTile(
      {required this.label,
      required this.semantics,
      required this.selected,
      required this.accent,
      required this.onTap,
      required this.child});
  final String label, semantics;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                  color: selected
                      ? Color.lerp(accent, Colors.white, .86)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border(
                      left: BorderSide(
                          color: selected ? accent : panel2, width: 2),
                      right: BorderSide(
                          color: selected ? accent : panel2, width: 2),
                      top: BorderSide(
                          color: selected ? accent : panel2, width: 2),
                      bottom: BorderSide(
                          color: selected ? accent : panel2, width: 4.5))),
              child: Stack(children: [
                Column(children: [
                  AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: child)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected ? accent : muted))),
                ]),
                if (selected)
                  Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white))),
              ]))));
}

/// The preview avatar: gently breathing, blinking now and then, and
/// popping with sparkles whenever something changes ([bump]).
class _LivePortrait extends StatefulWidget {
  const _LivePortrait({required this.look, required this.bump});
  final LearnerLook look;
  final int bump;
  @override
  State<_LivePortrait> createState() => _LivePortraitState();
}

class _LivePortraitState extends State<_LivePortrait>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _idle.stop();
      _pop.value = 1;
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LivePortrait old) {
    super.didUpdateWidget(old);
    if (old.bump != widget.bump && !_still) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([_idle, _pop]),
      builder: (context, _) {
        final t = _idle.value;
        final p = _pop.value;
        // Two quick blinks in each idle cycle.
        final blink = !_still && ((t > .46 && t < .485) || (t > .9 && t < .92));
        final pop = _still || _pop.status == AnimationStatus.dismissed
            ? 1.0
            : .9 + .1 * Curves.elasticOut.transform(p);
        final bob = _still ? 0.0 : math.sin(t * math.pi * 2) * 3;
        return Stack(children: [
          Positioned.fill(
              child: Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.scale(
                      scale: pop,
                      alignment: Alignment.bottomCenter,
                      child:
                          LearnerPortrait(look: widget.look, blink: blink)))),
          if (!_still && p > 0 && p < 1)
            Positioned.fill(
                child: IgnorePointer(
                    child: CustomPaint(painter: _SparklePainter(p)))),
        ]);
      });
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .42);
    final fade = (1 - t).clamp(0.0, 1.0);
    const colors = [
      Color(0xFFFFC62E), Color(0xFFFF6B4A), Color(0xFF7B5CFA), //
      Color(0xFF14B39C), Color(0xFFEC4899), Colors.white,
    ];
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 2 / 10 + .3;
      final distance =
          size.shortestSide * (.22 + .3 * Curves.easeOut.transform(t));
      final p =
          center + Offset(math.cos(a) * distance, math.sin(a) * distance * .8);
      final r = 5.0 * fade + 1;
      final path = Path();
      for (var k = 0; k < 8; k++) {
        final radius = k.isEven ? r : r * .4;
        final b = -math.pi / 2 + k * math.pi / 4;
        final q = p + Offset(math.cos(b) * radius, math.sin(b) * radius);
        k == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(path..close(),
          Paint()..color = colors[i % colors.length].withValues(alpha: fade));
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
