import 'package:flutter/material.dart';
import 'package:grocery_voice_list/utils/app_colors.dart';
import 'package:grocery_voice_list/widgets/custom_appbar.dart';

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppColors.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: 'How to Use'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // Introduction
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 34,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Create Your Grocery List by Voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Just tap the microphone and tell the app what you need.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorScheme.onPrimaryContainer.withOpacity(.75),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Getting Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _stepCard(
            context,
            number: '1',
            icon: Icons.mic_none_rounded,
            title: 'Tap the Microphone',
            description:
            'Tap the microphone button to start speaking your grocery items.',
          ),

          _stepCard(
            context,
            number: '2',
            icon: Icons.record_voice_over_outlined,
            title: 'Speak Naturally',
            description:
            'Say the item name, quantity and unit just like you normally would.',
          ),

          _stepCard(
            context,
            number: '3',
            icon: Icons.check_circle_outline_rounded,
            title: 'Review Your List',
            description:
            'Your spoken items are converted into grocery list items automatically.',
          ),

          const SizedBox(height: 28),

          const Text(
            'Things You Can Say',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _voiceExample(
            context,
            icon: Icons.add_circle_outline,
            title: 'Add items',
            examples: [
              'Add 2 kg potatoes',
              'I need 1 litre milk',
              'Add 5 bananas',
            ],
          ),

         /* _voiceExample(
            context,
            icon: Icons.playlist_add_rounded,
            title: 'Add multiple items',
            examples: [
              'Add 2 kg rice, 1 litre milk and 6 eggs',
              'I need apples, bananas and bread',
            ],
          ),*/

          _voiceExample(
            context,
            icon: Icons.remove_circle_outline,
            title: 'Remove items',
            examples: [
              'Remove milk',
              'Delete bananas from my list',
            ],
          ),

          /*_voiceExample(
            context,
            icon: Icons.edit_outlined,
            title: 'Change quantity',
            examples: [
              'Change milk to 2 litres',
              'Make potatoes 5 kg',
            ],
          ),*/

          const SizedBox(height: 28),

          // Tips
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Voice Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _tip('Speak clearly and at a normal speed.'),
                _tip('Try to mention quantity and unit.'),
                _tip('Speak in a quiet environment for better results.'),
                _tip('Review the list after adding multiple items.'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Text(
              'Tap the mic. Speak. Your list is ready! 🎙️',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
      BuildContext context, {
        required String number,
        required IconData icon,
        required String title,
        required String description,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $number',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceExample(
      BuildContext context, {
        required IconData icon,
        required String title,
        required List<String> examples,
      }) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...examples.map(
                (example) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$example"',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}