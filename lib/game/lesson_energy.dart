part of '../main.dart';

/// Colour of the lesson progress bar as a run of correct answers heats up.
Color _runColor(int run) => run >= 5
    ? const Color(0xFFFF7A45)
    : run >= 3
        ? const Color(0xFF58C27D)
        : const Color(0xFF8FC9EA);

/// A flame chip that pops each time the run grows.
class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.run});
  final int run;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child),
      child: run < 2
          ? const SizedBox.shrink(key: ValueKey('no-run'))
          : Container(
              key: ValueKey('run-$run'),
              padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
              decoration: BoxDecoration(
                  color: run >= 5
                      ? const Color(0xFFFFE6D9)
                      : const Color(0xFFFFF1DF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: run >= 5
                      ? const [
                          BoxShadow(
                              color: Color(0x66FF7A45),
                              blurRadius: 10,
                              spreadRadius: 1)
                        ]
                      : null),
              child: Semantics(
                  label: '$run correct in a row',
                  excludeSemantics: true,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 18,
                        color: run >= 5
                            ? const Color(0xFFE5482D)
                            : const Color(0xFFF08A24)),
                    Text('×$run',
                        style: const TextStyle(
                            color: amberInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ]))));
}

/// "+2 XP" rising from the prompt after a correct answer.
class _FloatingXp extends StatelessWidget {
  const _FloatingXp({super.key, required this.amount, required this.hot});
  final int amount;
  final bool hot;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      builder: (_, t, child) => Opacity(
          opacity: t < .15 ? t / .15 : (1 - (t - .6) / .4).clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, -46 * Curves.easeOutCubic.transform(t)),
              child: Transform.scale(
                  scale: .6 +
                      .4 *
                          Curves.elasticOut.transform((t / .4).clamp(0.0, 1.0)),
                  child: child))),
      child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bolt_rounded,
            color: hot ? const Color(0xFFFF7A45) : const Color(0xFFF2A51F),
            size: 22),
        Text('+$amount XP',
            style: TextStyle(
                color: hot ? const Color(0xFFE5482D) : amberInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Colors.white, blurRadius: 6),
                ])),
      ])));
}
