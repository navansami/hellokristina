part of '../main.dart';

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});
  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  int selected = 0;

  /// Which clip is playing: 'name', 'word' or null.
  String? playing;

  Future<void> _play(String what) async {
    final letter = alphabet[selected];
    final name = what == 'name';
    setState(() => playing = what);
    try {
      await SerbianAudio.play(
          name
              ? (letter.name.isEmpty ? letter.cyrillic : letter.name)
              : letter.wordLatin,
          name ? letter.nameAudio : letter.wordAudio);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    // Clear the "playing" glow once the clip has had time to finish.
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && playing == what) setState(() => playing = null);
    });
  }

  void _pick(int index) {
    learningFeedback.tap(sound: false);
    setState(() => selected = index);
    _play('name');
  }

  @override
  Widget build(BuildContext context) {
    final theme = unitTheme(2);
    final l = alphabet[selected];
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _PageHero(
              theme: theme,
              eyebrow: 'Alphabet',
              title: 'Serbian Cyrillic',
              subtitle: 'Tap any letter to hear how it sounds.',
              emoji: '🔤'),
          const SizedBox(height: 16),
          _Slab(
              edge: theme.light,
              child: Column(children: [
                Row(children: [
                  Semantics(
                      button: true,
                      label: 'Hear the letter ${l.cyrillic}',
                      excludeSemantics: true,
                      child: GestureDetector(
                          onTap: () => _play('name'),
                          child: AnimatedScale(
                              scale: playing == 'name' ? 1.08 : 1,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutBack,
                              child: Stack(clipBehavior: Clip.none, children: [
                                AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                            scale: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutBack),
                                            child: child),
                                    child: _LetterCoin(
                                        key: ValueKey(selected),
                                        letter: l.cyrillic,
                                        theme: theme)),
                                Positioned(
                                    right: -6,
                                    bottom: -4,
                                    child: _SpeakerDot(
                                        color: theme.deep,
                                        active: playing == 'name')),
                              ])))),
                  const SizedBox(width: 18),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            '${l.cyrillic} ${l.cyrillic.toLowerCase()}  ·  ${l.latin}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900)),
                        if (l.name.isNotEmpty)
                          Text('Say it: “${l.name}”',
                              style: TextStyle(
                                  color: theme.deep,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Sounds like ${l.sound}',
                            style: const TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w700,
                                height: 1.3)),
                        const SizedBox(height: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: theme.light,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('Letter ${selected + 1} of 30',
                                style: TextStyle(
                                    color: theme.deep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12))),
                      ])),
                ]),
                if (l.wordLatin.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Chunky(
                      fill: theme.light,
                      edge: theme.glow,
                      radius: 18,
                      onTap: () => _play('word'),
                      child: Semantics(
                          button: true,
                          label: 'Hear ${l.wordLatin}, ${l.wordEnglish}',
                          excludeSemantics: true,
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 10, 10, 10),
                              child: Row(children: [
                                Text(l.emoji,
                                    style: const TextStyle(fontSize: 34)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text.rich(
                                          TextSpan(children: [
                                            TextSpan(
                                                text: l.wordCyrillic.substring(
                                                    0,
                                                    l.cyrillic.length.clamp(0,
                                                        l.wordCyrillic.length)),
                                                style: TextStyle(
                                                    color: theme.deep,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            TextSpan(
                                                text: l.wordCyrillic.substring(
                                                    l.cyrillic.length.clamp(
                                                        0,
                                                        l.wordCyrillic
                                                            .length))),
                                          ]),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: ink)),
                                      Text('${l.wordLatin} · ${l.wordEnglish}',
                                          style: const TextStyle(
                                              color: muted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ])),
                                _SpeakerDot(
                                    color: theme.deep,
                                    active: playing == 'word'),
                              ])))),
                ],
              ])),
          const SizedBox(height: 22),
          _SectionLabel('Tap a letter to hear it', color: theme.deep),
          LayoutBuilder(builder: (context, c) {
            const gap = 8.0;
            final cell = (c.maxWidth - 5 * gap) / 6;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (var i = 0; i < alphabet.length; i++)
                SizedBox(
                    width: cell,
                    height: cell + 8,
                    child: _Chunky(
                        fill: selected == i ? theme.main : Colors.white,
                        edge: selected == i ? theme.deep : panel2,
                        radius: 14,
                        onTap: () => _pick(i),
                        child: Semantics(
                            label:
                                '${alphabet[i].cyrillic}, ${alphabet[i].latin}',
                            button: true,
                            excludeSemantics: true,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(alphabet[i].cyrillic,
                                      style: TextStyle(
                                          fontSize: c.maxWidth > 500 ? 28 : 22,
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                          color: selected == i
                                              ? Colors.white
                                              : ink)),
                                  Text(alphabet[i].latin,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: selected == i
                                              ? Colors.white
                                                  .withValues(alpha: .85)
                                              : muted)),
                                ])))),
            ]);
          }),
          const SizedBox(height: 22),
          _Slab(
              fill: const Color(0xFFFFF8E1),
              edge: const Color(0xFFFFE08A),
              child: const Row(children: [
                Text('💡', style: TextStyle(fontSize: 30)),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Serbian is written exactly as it sounds: one letter, one sound. Learn the 30 sounds and you can read any word aloud.',
                        style: TextStyle(
                            color: Color(0xFF7A5A00),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)))
              ])),
          const SizedBox(height: 8),
          const Text('  Audio pronunciations are AI-generated.',
              style: TextStyle(color: muted, fontSize: 12)),
        ]);
  }
}

/// A round speaker badge that glows while its clip plays.
class _SpeakerDot extends StatelessWidget {
  const _SpeakerDot({required this.color, required this.active});
  final Color color;
  final bool active;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
          color: active ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: .4),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null),
      child: Icon(Icons.volume_up_rounded,
          size: 20, color: active ? Colors.white : color));
}

/// A big glossy letter tile with a ledge, like the coins on the trail.
class _LetterCoin extends StatelessWidget {
  const _LetterCoin({super.key, required this.letter, required this.theme});
  final String letter;
  final UnitTheme theme;
  @override
  Widget build(BuildContext context) => Container(
      width: 96,
      height: 100,
      decoration: BoxDecoration(
          color: theme.deep, borderRadius: BorderRadius.circular(26)),
      alignment: Alignment.topCenter,
      child: Container(
          width: 96,
          height: 94,
          decoration: BoxDecoration(
              gradient: RadialGradient(
                  center: const Alignment(-.3, -.5),
                  radius: 1.1,
                  colors: [theme.glow, theme.main]),
              borderRadius: BorderRadius.circular(26)),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(10)))),
            Text(letter,
                style: const TextStyle(
                    fontSize: 58,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 3),
                          blurRadius: 4)
                    ])),
          ])));
}
