import 'package:flutter/material.dart';
import 'course_palette.dart';

class TactileButton extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: panel2,
            disabledForegroundColor: muted,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            side: outline ? const BorderSide(color: panel2) : null,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
}
