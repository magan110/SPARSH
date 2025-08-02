import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ModernButtonType { primary, secondary, outline, text, success, warning, error }

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return _buildLoadingButton(theme);
    }

    switch (type) {
      case ModernButtonType.primary:
        return _buildPrimaryButton(theme);
      case ModernButtonType.secondary:
        return _buildSecondaryButton(theme);
      case ModernButtonType.outline:
        return _buildOutlineButton(theme);
      case ModernButtonType.text:
        return _buildTextButton(theme);
      case ModernButtonType.success:
        return _buildSuccessButton(theme);
      case ModernButtonType.warning:
        return _buildWarningButton(theme);
      case ModernButtonType.error:
        return _buildErrorButton(theme);
    }
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
      decoration: BoxDecoration(
        color: SparshTheme.primaryBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(SparshTheme.textOnPrimary),
            ),
          ),
          const SizedBox(width: SparshTheme.spacing8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: SparshTheme.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: SparshTheme.primaryBlue,
          foregroundColor: SparshTheme.textOnPrimary,
          elevation: SparshTheme.elevation2,
          shadowColor: SparshTheme.primaryBlue.withOpacity(0.3),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: SparshTheme.surfaceSecondary,
          foregroundColor: SparshTheme.textPrimary,
          elevation: SparshTheme.elevation1,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: SparshTheme.primaryBlue,
          side: const BorderSide(color: SparshTheme.primaryBlue, width: 1.5),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: TextButton.styleFrom(
          foregroundColor: SparshTheme.primaryBlue,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing16, vertical: SparshTheme.spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusSm),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: SparshTheme.successGreen,
          foregroundColor: SparshTheme.textOnPrimary,
          elevation: SparshTheme.elevation2,
          shadowColor: SparshTheme.successGreen.withOpacity(0.3),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: SparshTheme.warningOrange,
          foregroundColor: SparshTheme.textOnPrimary,
          elevation: SparshTheme.elevation2,
          shadowColor: SparshTheme.warningOrange.withOpacity(0.3),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: SparshTheme.errorRed,
          foregroundColor: SparshTheme.textOnPrimary,
          elevation: SparshTheme.elevation2,
          shadowColor: SparshTheme.errorRed.withOpacity(0.3),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: SparshTheme.spacing24, vertical: SparshTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? SparshTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
