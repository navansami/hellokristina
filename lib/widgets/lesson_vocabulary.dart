part of '../main.dart';

class _VocabularyPage extends StatelessWidget {
  const _VocabularyPage(
      {required this.lesson, required this.word, required this.character});

  final Lesson lesson;
  final List<String>? word;
  final int character;

  // Use the same recorded sentence and translation that the course teaches.
  Question? _exampleFor(String term) {
    final target = foldSerbian(term);
    for (final unitLesson
        in lessons.where((l) => l.unitTitle == lesson.unitTitle)) {
      for (final q in unitLesson.questions) {
        if (q.audioAsset.isEmpty || q.type != 'Arrange the words') continue;
        final spoken = foldSerbian(q.audioText);
        if (spoken == target || !(' $spoken ').contains(' $target ')) continue;
        if (q.answerLanguage == 'sr' && spoken == foldSerbian(q.answer))
          return q;
        if (q.answerLanguage == 'en' && spoken == foldSerbian(q.prompt))
          return q;
      }
    }
    return null;
  }

  Widget _illustration() {
    final entry = word;
    if (entry != null) {
      final object = objectKeyFor(entry[2], entry[0]);
      if (object != null) return LearningObject(name: object);
      final greeting = const {
        'hello': '👋',
        'thank you': '🙏',
        'good day': '🌤️',
        'goodbye': '👋'
      }[entry[2].toLowerCase()];
      if (greeting != null)
        return Text(greeting, style: const TextStyle(fontSize: 82));
    }
    return AnimatedKristina(width: 104, height: 142, character: character);
  }

  @override
  Widget build(BuildContext context) {
    final entry = word;
    final example = entry == null ? null : _exampleFor(entry[0]);
    return LayoutBuilder(builder: (context, box) {
      final artHeight =
          math.min(225.0, box.maxHeight * (example == null ? .45 : .34));
      return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
              width: box.maxWidth,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                        color: panel,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(color: panel2),
                            borderRadius: BorderRadius.circular(16)),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: artHeight,
                              color: sky,
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: FittedBox(child: _illustration()))),
                          if (entry != null)
                            _SpokenRow(
                                text: entry[0],
                                script: entry[1],
                                meaning: entry[2],
                                asset: entry.length > 4 ? entry[4] : ''),
                          if (example != null) ...[
                            const Divider(color: panel2, height: 1),
                            _SpokenRow(
                                text: example.audioText,
                                meaning: example.answerLanguage == 'sr'
                                    ? example.prompt
                                    : example.answer,
                                asset: example.audioAsset),
                          ],
                        ])),
                    const SizedBox(height: 12),
                    KCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lesson.theoryTitle,
                                  style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(lesson.theoryBody,
                                  style: const TextStyle(
                                      color: muted, fontSize: 14, height: 1.3)),
                            ])),
                  ])));
    });
  }
}

class _SpokenRow extends StatelessWidget {
  const _SpokenRow(
      {required this.text,
      required this.meaning,
      required this.asset,
      this.script});
  final String text, meaning, asset;
  final String? script;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(text,
                  style: TextStyle(
                      color: ink,
                      fontSize: script == null ? 18 : 22,
                      fontWeight: FontWeight.w600)),
              if (script != null)
                Text(script!,
                    style: const TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 2),
              Text(meaning, style: const TextStyle(color: muted, fontSize: 15)),
            ])),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, children: [
          SerbianAudioButton(text: text, asset: asset),
          SerbianAudioButton(text: text, asset: asset, slow: true),
        ]),
      ]));
}
