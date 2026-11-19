part of '../main.dart';

/// The gradient banner at the top of each tab: same family as the unit
/// banners on the trail, with soft bubbles and a big emoji.
class _PageHero extends StatelessWidget {
  const _PageHero(
      {required this.theme,
      required this.eyebrow,
      required this.title,
      required this.emoji,
      this.subtitle,
      this.child});
  final UnitTheme theme;
  final String eyebrow, title, emoji;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: theme.deep, offset: const Offset(0, 5), blurRadius: 0),
            BoxShadow(
                color: theme.main.withValues(alpha: .28),
                offset: const Offset(0, 12),
                blurRadius: 22),
          ]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(children: [
            Positioned(
                right: -36,
                top: -40,
                child: _HeroBubble(size: 150, opacity: .12)),
            Positioned(
                left: -30,
                bottom: -54,
                child: _HeroBubble(size: 120, opacity: .08)),
            Positioned(
                right: 14,
                top: 12,
                child: ExcludeSemantics(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 52, shadows: [
                          Shadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ])))),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow.toUpperCase(),
                          style: display(12.5,
                              color: Colors.white.withValues(alpha: .85),
                              letterSpacing: 1.6)),
                      const SizedBox(height: 4),
                      Padding(
                          padding: const EdgeInsets.only(right: 64),
                          child: Text(title,
                              style: display(30,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                  height: 1.08))),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: Text(subtitle!,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: .9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14))),
                      ],
                      if (child != null) ...[
                        const SizedBox(height: 14),
                        child!,
                      ],
                    ])),
          ])));
}

class _HeroBubble extends StatelessWidget {
  const _HeroBubble({required this.size, required this.opacity});
  final double size, opacity;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity)));
}

/// A thin white bar on a coloured banner.
class _HeroBar extends StatelessWidget {
  const _HeroBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
          height: 12,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: Colors.white.withValues(alpha: .28)),
            FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: const DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(8))))),
          ])));
}

/// An all-caps section label with an optional count or action on the right.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = muted, this.trailing});
  final String text;
  final Color color;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(text.toUpperCase(),
                style: display(13.5, color: color, letterSpacing: 1.4))),
        if (trailing != null) trailing!,
      ]));
}

/// A white card with a chunky bottom ledge, for content that isn't a button.
class _Slab extends StatelessWidget {
  const _Slab(
      {required this.child,
      this.fill = Colors.white,
      this.edge = panel2,
      this.padding = const EdgeInsets.all(16),
      this.radius = 20});
  final Widget child;
  final Color fill, edge;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border(
              left: BorderSide(color: edge, width: 2),
              right: BorderSide(color: edge, width: 2),
              top: BorderSide(color: edge, width: 2),
              bottom: BorderSide(color: edge, width: 4.5))),
      child: child);
}
