import 'package:flutter/material.dart';

class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color, foreground;
  final bool outline;
  const TactileButton(
      {super.key,
      required this.label,
      required this.onTap,
      required this.color,
      required this.foreground,
      this.outline = false});
  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : const Color(0xFF293B43);
    final edge = Color.lerp(face, Colors.black, .22)!;
    return SizedBox(
        height: 56,
        width: double.infinity,
        child: Listener(
            onPointerDown:
                enabled ? (_) => setState(() => pressed = true) : null,
            onPointerUp: (_) => setState(() => pressed = false),
            onPointerCancel: (_) => setState(() => pressed = false),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(
                    top: pressed ? 4 : 0, bottom: pressed ? 0 : 4),
                decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(15),
                    border: widget.outline
                        ? Border.all(color: const Color(0xFF435660), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(color: edge, offset: Offset(0, pressed ? 0 : 4))
                    ]),
                child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(15),
                        child: Center(
                            child: Text(widget.label,
                                style: TextStyle(
                                    color: enabled
                                        ? widget.foreground
                                        : const Color(0xFF6A808C),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: .7))))))));
  }
}
