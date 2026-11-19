part of '../main.dart';

class WordsPage extends StatefulWidget {
  final Set<String> done;
  final int mistakes;
  final VoidCallback? onMistakes;
  const WordsPage(
      {super.key, required this.done, this.mistakes = 0, this.onMistakes});
  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  String query = '';
  String? open;

  @override
  Widget build(BuildContext context) {
    final titles = lessons.map((l) => l.unitTitle).toSet().toList();
    final unitOfLesson = {
      for (final lesson in lessons) lesson.id: titles.indexOf(lesson.unitTitle)
    };
    final learned = <(int, List<String>)>[
      for (var i = 0; i < words.length && i < wordLesson.length; i++)
        if (widget.done.contains(wordLesson[i]))
          (unitOfLesson[wordLesson[i]] ?? 0, words[i])
    ];
    final needle = query.trim().toLowerCase();
    final shown = learned
        .where((entry) =>
            needle.isEmpty ||
            entry.$2.take(3).any((x) => x.toLowerCase().contains(needle)))
        .toList();
    final units = shown.map((entry) => entry.$1).toSet().toList()..sort();
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _PageHero(
              theme: unitTheme(1),
              eyebrow: 'Your word bank',
              title: 'Words you know',
              subtitle: '${learned.length} of ${words.length} collected',
              emoji: '📚',
              child: _HeroBar(
                  value: words.isEmpty ? 0 : learned.length / words.length)),
          const SizedBox(height: 16),
          _MistakesCard(count: widget.mistakes, onTap: widget.onMistakes),
          const SizedBox(height: 18),
          TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: muted),
                  hintText: 'Search Serbian or English',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: panel2, width: 2)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: purple, width: 2)))),
          const SizedBox(height: 6),
          const Text('  Audio pronunciations are AI-generated.',
              style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 14),
          if (learned.isEmpty)
            const _Slab(
                child: Row(children: [
              Text('🌱', style: TextStyle(fontSize: 34)),
              SizedBox(width: 14),
              Expanded(
                  child: Text('Finish your first lesson to collect words.',
                      style: TextStyle(
                          color: muted, fontWeight: FontWeight.w700))),
            ]))
          else if (shown.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No words match “$query”.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted))),
          for (final unit in units) ...[
            _UnitWordsHeader(
                unit: unit,
                title: unit < titles.length ? titles[unit] : '',
                count: shown.where((entry) => entry.$1 == unit).length),
            for (final entry in shown.where((entry) => entry.$1 == unit))
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WordCard(
                      word: entry.$2,
                      theme: unitTheme(unit),
                      open: open == entry.$2[0],
                      onTap: () => setState(() =>
                          open = open == entry.$2[0] ? null : entry.$2[0]))),
            const SizedBox(height: 10),
          ],
        ]);
  }
}

class _UnitWordsHeader extends StatelessWidget {
  const _UnitWordsHeader(
      {required this.unit, required this.title, required this.count});
  final int unit, count;
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = unitTheme(unit);
    return Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  color: theme.main, borderRadius: BorderRadius.circular(20)),
              child: Text('UNIT ${unit + 1}',
                  style: display(12, color: Colors.white, letterSpacing: 1.2))),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display(17, color: theme.deep))),
          Text('$count',
              style: display(15, color: theme.main, weight: FontWeight.w700)),
        ]));
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard(
      {required this.word,
      required this.theme,
      required this.open,
      required this.onTap});
  final List<String> word;
  final UnitTheme theme;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Chunky(
      fill: Colors.white,
      edge: open ? theme.main : panel2,
      radius: 18,
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Column(children: [
            Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: theme.light,
                      borderRadius: BorderRadius.circular(14)),
                  child: SerbianAudioButton(
                      text: word[0], asset: word.length > 4 ? word[4] : '')),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(word[0],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(word[1],
                        style: const TextStyle(color: muted, fontSize: 13)),
                  ])),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(word[2],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: theme.deep,
                          fontWeight: FontWeight.w800,
                          fontSize: 14))),
            ]),
            AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: open && word.length > 3
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: theme.light,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('SAY IT  ·  ${word[3]}',
                                style: TextStyle(
                                    color: theme.deep,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1))))
                    : const SizedBox(width: double.infinity)),
          ])));
}

/// The way into a session made only of exercises the learner keeps missing.
class _MistakesCard extends StatelessWidget {
  const _MistakesCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = count >= minMistakeSession && onTap != null;
    return _Chunky(
        fill: ready ? const Color(0xFFFFEEF3) : Colors.white,
        edge: ready ? const Color(0xFFF6A9C0) : panel2,
        radius: 20,
        onTap: ready ? onTap : null,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(children: [
              Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: ready ? Colors.white : mint,
                      shape: BoxShape.circle),
                  child: Text(ready ? '🩹' : '✨',
                      style: const TextStyle(fontSize: 26))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(ready ? 'Fix your mistakes' : 'No mistakes to fix',
                        style: display(19)),
                    Text(
                        ready
                            ? '$count exercises you missed, ready to practise'
                            : count > 0
                                ? '$count to fix. A session opens at $minMistakeSession.'
                                : 'Exercises you miss will show up here.',
                        style: const TextStyle(color: muted, fontSize: 13)),
                  ])),
              if (ready)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                        color: pink,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0xFFB8256F), offset: Offset(0, 3))
                        ]),
                    child: Text('START',
                        style: display(14,
                            color: Colors.white, letterSpacing: .8))),
            ])));
  }
}
