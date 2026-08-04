import 'package:flutter/material.dart';
import 'package:grocery_voice_list/widgets/custom_appbar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: CustomAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: colors.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your Privacy Matters',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This policy explains how your information is handled '
                  'when you use the Voice Grocery List app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    color: colors.onPrimaryContainer.withOpacity(.75),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Last updated: August 3, 2026',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 24),

          _section(
            context,
            icon: Icons.info_outline,
            title: 'Introduction',
            text:
                'Voice Grocery List is designed to help you create and '
                'manage grocery lists using voice and manual input. '
                'We respect your privacy and are committed to protecting '
                'your information.',
          ),

          _section(
            context,
            icon: Icons.mic_none_rounded,
            title: 'Microphone Access',
            text:
                'The app may request access to your device microphone so '
                'you can add, update, or remove grocery items using voice '
                'commands.\n\n'
                'Microphone access is only used when required for voice '
                'functionality. You can deny or revoke microphone permission '
                'at any time through your device settings.',
          ),

          _section(
            context,
            icon: Icons.record_voice_over_outlined,
            title: 'Speech Recognition',
            text:
                'Voice input may be processed using speech recognition '
                'services available on your device or provided by your '
                'device platform. Depending on your device and speech '
                'recognition provider, audio or speech data may be processed '
                'according to that provider\'s privacy practices.',
          ),

          _section(
            context,
            icon: Icons.storage_outlined,
            title: 'Grocery List Data',
            text:
                'Information you add to your grocery lists, such as item '
                'names, quantities, and units, is used to provide the app\'s '
                'grocery list features.\n\n'
                'If your version of the app stores grocery lists only on '
                'your device, this information is not uploaded to our '
                'servers.',
          ),

          _section(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            text:
                'We do not intentionally collect personal information such '
                'as your name, address, phone number, or payment information '
                'unless a feature clearly asks you to provide it.',
          ),

          _section(
            context,
            icon: Icons.analytics_outlined,
            title: 'Analytics & Crash Information',
            text:
                'If analytics or crash-reporting services are enabled in '
                'the app, they may collect limited technical information '
                'such as device type, operating system version, app version, '
                'and crash diagnostics. This information is used to improve '
                'app stability and performance.',
          ),

          _section(
            context,
            icon: Icons.security_outlined,
            title: 'Data Security',
            text:
                'We take reasonable measures to protect information handled '
                'by the app. However, no electronic storage or transmission '
                'method can be guaranteed to be completely secure.',
          ),

          _section(
            context,
            icon: Icons.child_care_outlined,
            title: 'Children\'s Privacy',
            text:
                'The app is not designed to knowingly collect personal '
                'information from children. If you believe that personal '
                'information from a child has been collected, please contact '
                'us so the issue can be reviewed.',
          ),

          _section(
            context,
            icon: Icons.update_rounded,
            title: 'Changes to This Policy',
            text:
                'We may update this Privacy Policy when app functionality '
                'or privacy practices change. The updated policy will show '
                'a revised "Last updated" date.',
          ),

          _section(
            context,
            icon: Icons.email_outlined,
            title: 'Contact Us',
            text:
                'If you have questions or concerns about this Privacy Policy, '
                'please contact us at:\n\n'
                'support@niviclouds.com',
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
