import 'package:flutter/material.dart';
import 'course_palette.dart';
import '../feedback/learning_feedback.dart';

/// A chunky button with a darker ledge underneath. Pressing it sinks the face
/// onto the ledge, so every action feels physical.
class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color, foreground;
  final bool outline;
  const TactileButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.foreground,
    this.outline = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  static const _ledge = 5.0;
  bool _down = false;

  void _press(bool down) {
    if (!mounted || widget.onTap == null || down == _down) return;
    // A small buzz as the button bottoms out makes every press feel real.
    if (down) learningFeedback.touch();
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : panel2;
    final ledge = !enabled
        ? const Color(0xFFC9D0D3)
        : widget.outline
            ? panel2
            : Color.lerp(widget.color, Colors.black, .22)!;
    final sink = _down ? _ledge : 0.0;
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Stack(children: [
          Positioned.fill(
              top: _ledge,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: ledge, borderRadius: BorderRadius.circular(16)))),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: sink,
            height: 54 - _ledge,
            child: FilledButton(
              onPressed: widget.onTap,
              style: FilledButton.styleFrom(
                backgroundColor: face,
                foregroundColor: widget.foreground,
                disabledBackgroundColor: panel2,
                disabledForegroundColor: muted,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: widget.outline ? const BorderSide(color: panel2) : null,
                textStyle:
                    display(17, weight: FontWeight.w600, letterSpacing: .6),
              ),
              child: Text(widget.label, textAlign: TextAlign.center),
            ),
          ),
        ]),
      ),
    );
  }
}
