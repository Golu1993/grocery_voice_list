import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showLogoInLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showLogoInLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton && !showLogoInLeading,
      leadingWidth: showLogoInLeading ? 100 : null,
      leading: showLogoInLeading
          ? Image.asset('images/trans_logo.webp',)
          : null,
      title: Text(title),
      centerTitle: true,
      elevation: 0,
      //  backgroundColor: Colors.blue,
      foregroundColor: Colors.black,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
