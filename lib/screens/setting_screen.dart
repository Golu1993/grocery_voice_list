import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/about_app.dart';
import '../screens/how_to_use.dart';
import '../screens/privacy_policy.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/utility.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _signingOut = false;
  String? _signOutError;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() {
      _signingOut = true;
      _signOutError = null;
    });
    try {
      await AuthService.signOut();
    } catch (error) {
      if (mounted) {
        setState(() => _signOutError = AuthService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.of(context).surfaceContainerLowest,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Account'),
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user?.displayName ?? 'Google account'),
              subtitle: Text(user?.email ?? 'Signed in'),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            child: ListTile(
              leading: _signingOut
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              title: Text(_signingOut ? 'Signing out…' : 'Sign out'),
              onTap: _signingOut ? null : _signOut,
            ),
          ),
          if (_signOutError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _signOutError!,
                style: TextStyle(color: AppColors.of(context).error),
              ),
            ),
          const SizedBox(height: 20),
          _sectionTitle("Information"),

          _settingTile(
            icon: Icons.info_outline,
            title: "About App",
            subtitle: "App information",
            onTap: () {
              Get.to(() => AboutAppPage());
            },
          ),

          _settingTile(
            icon: Icons.menu_book_outlined,
            title: "How to Use",
            subtitle: "Learn how the app works",
            onTap: () {
              Get.to(() => HowToUsePage());
            },
          ),

          _settingTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Read our privacy policy",
            onTap: () {
              Get.to(() => PrivacyPolicyPage());
            },
          ),

          _settingTile(
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            subtitle: "Usage terms and conditions",
            onTap: () {
              Utility.openPrivacyPolicy();
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle("Support"),

          _settingTile(
            icon: Icons.email_outlined,
            title: "Contact Us",
            subtitle: "Send feedback or report issues",
            onTap: () {
              Utility.openPrivacyPolicy();
            },
          ),

          _settingTile(
            icon: Icons.star_border,
            title: "Rate App",
            subtitle: "Leave a review on App/Play Store",
            onTap: () {
              Utility.rateApp();
            },
          ),

          _settingTile(
            icon: Icons.share_outlined,
            title: "Share App",
            subtitle: "Invite your friends",
            onTap: () {
              Utility.shareApp();
            },
          ),

          const SizedBox(height: 24),

          Center(
            child: FutureBuilder<String>(
              future: Utility.appVersion(),
              builder: (context, snapshot) {
                return Center(
                  child: Text(
                    snapshot.hasData ? "Version ${snapshot.data}" : "",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.of(context).primaryContainer,
          child: Icon(icon, color: AppColors.of(context).primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
