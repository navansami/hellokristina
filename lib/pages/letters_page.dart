part of '../main.dart';

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});
  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = unitTheme(2);
    final l = letters[selected];
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _PageHero(
              theme: theme,
              eyebrow: 'Alphabet',
              title: 'Serbian Cyrillic',
              subtitle: 'Explore the sounds of all 30 letters.',
              emoji: '🔤'),
          const SizedBox(height: 16),
          _Slab(
              edge: theme.light,
              child: Row(children: [
                AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                            parent: animation, curve: Curves.easeOutBack),
                        child: child),
                    child: _LetterCoin(
                        key: ValueKey(selected), letter: l[0], theme: theme)),
                const SizedBox(width: 18),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${l[0]}  =  ${l[1]}',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Sounds like “${l[2]}”',
                          style: const TextStyle(
                              color: muted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
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
              ])),
          const SizedBox(height: 22),
          _SectionLabel('Tap a letter', color: theme.deep),
          LayoutBuilder(builder: (context, c) {
            const gap = 8.0;
            final cell = (c.maxWidth - 5 * gap) / 6;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (var i = 0; i < letters.length; i++)
                SizedBox(
                    width: cell,
                    height: cell + 8,
                    child: _Chunky(
                        fill: selected == i ? theme.main : Colors.white,
                        edge: selected == i ? theme.deep : panel2,
                        radius: 14,
                        onTap: () => setState(() => selected = i),
                        child: Semantics(
                            label: '${letters[i][0]}, ${letters[i][1]}',
                            excludeSemantics: true,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(letters[i][0],
                                      style: TextStyle(
                                          fontSize: c.maxWidth > 500 ? 28 : 22,
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                          color: selected == i
                                              ? Colors.white
                                              : ink)),
                                  Text(letters[i][1],
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
                        'Serbian uses both Cyrillic and Latin. You’ll see both as you learn.',
                        style: TextStyle(
                            color: Color(0xFF7A5A00),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)))
              ])),
        ]);
  }
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
