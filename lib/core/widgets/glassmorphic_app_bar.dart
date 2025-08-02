import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'brutalist_button.dart';

class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final double height;

  const GlassmorphicAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onBackPressed,
    this.height = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SparshTheme.spacing16),
                child: Row(
                  children: [
                    if (showBackButton)
                      BrutalistButton(
                        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(SparshTheme.spacing8),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    if (showBackButton) const SizedBox(width: SparshTheme.spacing16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
