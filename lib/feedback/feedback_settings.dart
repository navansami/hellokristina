import 'package:flutter/material.dart';
import 'learning_feedback.dart';

Future<void> showFeedbackSettings(BuildContext context) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF192A32),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Learning feedback',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 24)),
                          const SizedBox(height: 6),
                          const Text('Make your lessons feel right for you.',
                              style: TextStyle(color: Color(0xFF93A7B2))),
                          const SizedBox(height: 14),
                          const FeedbackSettingsPanel(),
                        ])))));

class FeedbackSettingsPanel extends StatelessWidget {
  const FeedbackSettingsPanel({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: learningFeedback,
      builder: (context, _) =>
          Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Speak selected words',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: const Text('Hear Serbian tiles as you select them',
                    style: TextStyle(fontSize: 12, color: Color(0xFF93A7B2))),
                value: learningFeedback.spokenWords,
                onChanged: learningFeedback.setSpokenWords),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound effects',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: const Text(
                    'Soft taps, correct answers and celebrations',
                    style: TextStyle(fontSize: 12, color: Color(0xFF93A7B2))),
                value: learningFeedback.sounds,
                onChanged: learningFeedback.setSounds),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibration',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: const Text('Gentle feedback on supported devices',
                    style: TextStyle(fontSize: 12, color: Color(0xFF93A7B2))),
                value: learningFeedback.vibration,
                onChanged: learningFeedback.setVibration),
          ]));
}
