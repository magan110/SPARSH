import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrutalistButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isSelected;
  final double borderWidth;
  final Color? borderColor;

  const BrutalistButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.isSelected = false,
    this.borderWidth = 3.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected 
        ? (backgroundColor ?? Colors.black)
        : (backgroundColor ?? Colors.white);
    final fgColor = isSelected 
        ? (foregroundColor ?? Colors.white)
        : (foregroundColor ?? Colors.black);

    return Container(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: SparshTheme.spacing16,
              vertical: SparshTheme.spacing12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: borderColor ?? Colors.black,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
