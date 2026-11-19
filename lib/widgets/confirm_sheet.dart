import 'package:flutter/material.dart';

import '../feedback/learning_feedback.dart';
import 'course_palette.dart';
import 'tactile_button.dart';

/// Asks before something that would lose work. The safe choice is the big
/// button; the destructive one is a quieter red text button underneath.
/// Returns true only when the learner chooses to go ahead.
Future<bool> confirmSheet(BuildContext context,
    {required String emoji,
    required String title,
    required String body,
    required String stay,
    required String leave}) async {
  learningFeedback.touch();
  final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 56))),
                const SizedBox(height: 8),
                Text(title,
                    textAlign: TextAlign.center,
                    style: display(26, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: muted, fontSize: 15, height: 1.35)),
                const SizedBox(height: 22),
                TactileButton(
                    label: stay,
                    color: const Color(0xFF16A36A),
                    foreground: Colors.white,
                    onTap: () => Navigator.pop(context, false)),
                const SizedBox(height: 6),
                SizedBox(
                    width: double.infinity,
                    child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: red,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text(leave,
                            style:
                                display(16, color: red, letterSpacing: .4)))),
              ]))));
  return result ?? false;
}
