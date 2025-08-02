import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int? maxLines;
  final bool enabled;

  const ModernInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SparshTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: SparshTheme.spacing8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onTap: onTap,
          onChanged: onChanged,
          readOnly: readOnly,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? SparshTheme.surfaceSecondary : SparshTheme.surfaceTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.borderLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.errorRed, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.errorRed, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.borderLight.withOpacity(0.5), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SparshTheme.spacing16,
              vertical: SparshTheme.spacing16,
            ),
          ),
        ),
      ],
    );
  }
}

class ModernDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final bool enabled;

  const ModernDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SparshTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: SparshTheme.spacing8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor: enabled ? SparshTheme.surfaceSecondary : SparshTheme.surfaceTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.borderLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.errorRed, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.errorRed, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
              borderSide: BorderSide(color: SparshTheme.borderLight.withOpacity(0.5), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SparshTheme.spacing16,
              vertical: SparshTheme.spacing16,
            ),
          ),
        ),
      ],
    );
  }
}
