import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurIntensity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.blurIntensity = 10.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: Container(
            padding: padding ?? const EdgeInsets.all(SparshTheme.spacing16),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
                width: borderWidth,
              ),
              boxShadow: boxShadow ?? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
