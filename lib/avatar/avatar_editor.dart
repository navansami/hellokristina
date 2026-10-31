import 'package:flutter/material.dart';

import 'learner_look.dart';
import 'learner_portrait.dart';

const _bg = Color(0xFF131F24);
const _panel2 = Color(0xFF2C404B);
const _blue = Color(0xFF49C0F8);
const _muted = Color(0xFF93A7B2);

class AvatarEditor extends StatefulWidget {
  final LearnerLook look;
  final Future<void> Function(LearnerLook look) onDone;
  const AvatarEditor({super.key, required this.look, required this.onDone});

  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  late LearnerLook draft = widget.look;
  int category = 0;
  bool saving = false;

  static const _names = [
    'Skin',
    'Body',
    'Eyes',
    'Hair',
    'Glasses',
    'Headwear',
    'Clothing',
    'Background'
  ];
  static const _icons = [
    Icons.face_retouching_natural_rounded,
    Icons.accessibility_new_rounded,
    Icons.visibility_rounded,
    Icons.content_cut_rounded,
    Icons.lens_blur_rounded,
    Icons.school_rounded,
    Icons.checkroom_rounded,
    Icons.palette_outlined,
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            foregroundColor: Colors.white,
            leading: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded)),
            title: const Text('Edit Avatar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            actions: [
              TextButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'SAVING' : 'DONE',
                      style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6)))
            ]),
        body: LayoutBuilder(builder: (context, constraints) {
          final preview =
              (constraints.maxHeight * .34).clamp(168.0, 300.0);
          return Column(children: [
            SizedBox(
                height: preview,
                width: double.infinity,
                child: ColoredBox(
                    color: draft.backgroundColor,
                    child: Center(
                        child: SizedBox(
                            width: preview * .86,
                            height: preview * .92,
                            child: LearnerPortrait(look: draft))))),
            SizedBox(
                height: 64,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _names.length,
                    itemBuilder: (context, index) {
                      final selected = index == category;
                      return Semantics(
                          button: true,
                          selected: selected,
                          label: _names[index],
                          child: InkWell(
                              onTap: () => setState(() => category = index),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(_icons[index],
                                            color: selected ? _blue : _muted,
                                            size: 28),
                                        const SizedBox(height: 8),
                                        Container(
                                            width: 36,
                                            height: 3,
                                            color: selected
                                                ? _blue
                                                : Colors.transparent)
                                      ]))));
                    })),
            const Divider(height: 1, color: _panel2),
            Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [_panel()])),
          ]);
        }));
  }

  Widget _panel() {
    switch (category) {
      case 0:
        return _colors('Skin tone', LearnerLook.skins, draft.skin,
            (index) => draft = draft.copyWith(skin: index), 'Skin tone');
      case 1:
        return _styles('Body', LearnerLook.bodyCount, draft.body, (index) {
          draft = draft.copyWith(body: index);
        }, (index) => draft.copyWith(body: index), 'Body', headOnly: false);
      case 2:
        return Column(children: [
          _colors('Eye color', LearnerLook.eyeColors, draft.eye,
              (index) => draft = draft.copyWith(eye: index), 'Eye color'),
          const SizedBox(height: 22),
          _styles(
              'Expression',
              LearnerLook.expressionCount,
              draft.expression,
              (index) => draft = draft.copyWith(expression: index),
              (index) => draft.copyWith(expression: index),
              'Expression'),
        ]);
      case 3:
        return Column(children: [
          _colors(
              'Main hair color',
              LearnerLook.hairColors,
              draft.hairColor,
              (index) => draft = draft.copyWith(
                  hairColor: index, hair: draft.hair == 7 ? 0 : draft.hair),
              'Hair color'),
          const SizedBox(height: 22),
          _styles(
              'Hairstyle',
              LearnerLook.hairStyleCount,
              draft.hair,
              (index) => draft = draft.copyWith(hair: index),
              (index) => draft.copyWith(hair: index),
              'Hairstyle'),
        ]);
      case 4:
        return Column(children: [
          _colors(
              'Glasses color',
              LearnerLook.glassesColors,
              draft.glassesColor,
              (index) => draft = draft.copyWith(
                  glassesColor: index,
                  glasses: draft.glasses == 0 ? 1 : draft.glasses),
              'Glasses color'),
          const SizedBox(height: 22),
          _styles(
              'Glasses',
              LearnerLook.glassesStyleCount,
              draft.glasses,
              (index) => draft = draft.copyWith(glasses: index),
              (index) => draft.copyWith(glasses: index),
              'Glasses'),
        ]);
      case 5:
        return Column(children: [
          _colors(
              'Headwear color',
              LearnerLook.hatColors,
              draft.hatColor,
              (index) => draft = draft.copyWith(
                  hatColor: index, hat: draft.hat == 0 ? 1 : draft.hat),
              'Headwear color'),
          const SizedBox(height: 22),
          _styles(
              'Headwear',
              LearnerLook.hatStyleCount,
              draft.hat,
              (index) => draft = draft.copyWith(hat: index),
              (index) => draft.copyWith(hat: index),
              'Headwear'),
        ]);
      case 6:
        return _colors('Clothing color', LearnerLook.shirts, draft.shirt,
            (index) => draft = draft.copyWith(shirt: index), 'Clothing color');
      default:
        return _colors(
            'Background color',
            LearnerLook.backgrounds,
            draft.background,
            (index) => draft = draft.copyWith(background: index),
            'Background color');
    }
  }

  Widget _colors(String title, List<Color> colors, int selected,
      void Function(int index) apply, String kind) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final on = index == selected;
            return Semantics(
                button: true,
                selected: on,
                label: '$kind ${index + 1}',
                child: GestureDetector(
                    onTap: () => setState(() => apply(index)),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: on ? _blue : Colors.transparent,
                                width: 3)),
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: const Color(0xFF24343C),
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: DecoratedBox(
                                    decoration: BoxDecoration(
                                        color: colors[index],
                                        borderRadius:
                                            BorderRadius.circular(10))))))));
          })
    ]);
  }

  Widget _styles(
      String title,
      int count,
      int selected,
      void Function(int index) apply,
      LearnerLook Function(int index) preview,
      String kind,
      {bool headOnly = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15),
          itemCount: count,
          itemBuilder: (context, index) {
            final on = index == selected;
            return Semantics(
                button: true,
                selected: on,
                label: '$kind ${index + 1}',
                child: GestureDetector(
                    onTap: () => setState(() => apply(index)),
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: const Color(0xFF1B2A32),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: on ? _blue : _panel2, width: on ? 3 : 2)),
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: LearnerPortrait(
                                look: preview(index), headOnly: headOnly)))));
          })
    ]);
  }
}
