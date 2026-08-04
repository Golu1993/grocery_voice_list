import 'package:flutter/material.dart';
import 'package:grocery_voice_list/utils/app_colors.dart';
import 'package:grocery_voice_list/utils/utility.dart';
import 'package:grocery_voice_list/widgets/custom_appbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  late Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = Utility.appVersion();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: CustomAppBar(title: 'About Vocart'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 40,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vocart',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Simply Speak. Smartly Shop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _contentCard(
            context,
            child: Text(
              'Vocart is an intelligent voice-powered shopping list '
                  'application that helps you create, organize, and manage '
                  'your shopping lists effortlessly.\n\n'
                  'Using advanced speech recognition, Vocart converts your '
                  'spoken words into organized shopping items, allowing you '
                  'to build lists quickly without typing.\n\n'
                  'Whether you\'re shopping for groceries, household '
                  'essentials, or personal items, Vocart makes the process '
                  'faster, simpler, and more convenient.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 26),

          _sectionTitle(
            context,
            Icons.auto_awesome_outlined,
            'Key Features',
          ),

          const SizedBox(height: 12),

          _feature(
            context,
            Icons.mic_rounded,
            'Voice-to-List',
            'Instantly add shopping items using natural voice commands.',
          ),

          _feature(
            context,
            Icons.shopping_cart_outlined,
            'Multiple Shopping Lists',
            'Create and manage separate lists for groceries, home, office, travel, and more.',
          ),

          _feature(
            context,
            Icons.category_outlined,
            'Smart Categorization',
            'Automatically organize items into relevant categories for a better shopping experience.',
          ),

          _feature(
            context,
            Icons.edit_outlined,
            'Easy Editing',
            'Modify, delete, or update items with just a few taps.',
          ),

          _feature(
            context,
            Icons.search_rounded,
            'Quick Search',
            'Find items instantly within your shopping lists.',
          ),

          _feature(
            context,
            Icons.check_circle_outline_rounded,
            'Checklist Mode',
            'Mark items as purchased while shopping.',
          ),

          _feature(
            context,
            Icons.phone_android_rounded,
            'Simple & Intuitive Interface',
            'A clean, modern design that is easy for everyone to use.',
          ),

          _feature(
            context,
            Icons.language_rounded,
            'Multi-Language Voice Support',
            'Add items using your preferred supported language.',
          ),

          _feature(
            context,
            Icons.cloud_outlined,
            'Cloud Sync',
            'Securely sync your shopping lists across devices when enabled.',
          ),

          _feature(
            context,
            Icons.lock_outline_rounded,
            'Privacy First',
            'Your data is protected and handled securely.',
          ),

          const SizedBox(height: 26),

          _sectionTitle(
            context,
            Icons.favorite_border_rounded,
            'Why Choose Vocart?',
          ),

          const SizedBox(height: 12),

          _contentCard(
            context,
            child: Column(
              children: [
                _benefit(
                  context,
                  'Save time by eliminating manual typing.',
                ),
                _benefit(
                  context,
                  'Create shopping lists in seconds.',
                ),
                _benefit(
                  context,
                  'Stay organized with smart item management.',
                ),
                _benefit(
                  context,
                  'Reduce the chances of forgetting important items.',
                ),
                _benefit(
                  context,
                  'Designed for speed, simplicity, and everyday convenience.',
                  showBottomSpace: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Bottom Branding
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 28,
                  color: colors.primary,
                ),
                const SizedBox(height: 8),

                const Text(
                  'Vocart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Simply Speak. Smartly Shop.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 12),

                FutureBuilder<String>(
                  future: _versionFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    return Text(
                      'Version ${snapshot.data}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withOpacity(.7),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      BuildContext context,
      IconData icon,
      String title,
      ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _feature(
      BuildContext context,
      IconData icon,
      String title,
      String description,
      ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
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
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
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

  Widget _contentCard(
      BuildContext context, {
        required Widget child,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.5),
        ),
      ),
      child: child,
    );
  }

  Widget _benefit(
      BuildContext context,
      String text, {
        bool showBottomSpace = true,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpace ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}