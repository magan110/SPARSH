import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool showBackButton;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.gradient,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? SparshTheme.appBarGradient,
        color: gradient == null ? (backgroundColor ?? SparshTheme.primaryBlue) : null,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(SparshTheme.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: SparshTheme.textPrimary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: SparshTheme.textOnPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
              ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        automaticallyImplyLeading: showBackButton,
        actions: actions,
        iconTheme: const IconThemeData(
          color: SparshTheme.textOnPrimary,
          size: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(SparshTheme.radiusLg),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ModernSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final Gradient? gradient;

  const ModernSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 200.0,
    this.flexibleSpace,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: SparshTheme.textOnPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
      ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace ??
          Container(
            decoration: BoxDecoration(
              gradient: gradient ?? SparshTheme.appBarGradient,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(SparshTheme.radiusLg),
              ),
            ),
          ),
      iconTheme: const IconThemeData(
        color: SparshTheme.textOnPrimary,
        size: 24,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(SparshTheme.radiusLg),
        ),
      ),
    );
  }
}
