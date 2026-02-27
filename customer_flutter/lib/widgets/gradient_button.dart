import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Gradient button widget with purple to cyan gradient
/// Supports loading state and disabled state
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool outlined;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.gradient,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    if (outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.whiteColor,
            side: const BorderSide(
              color: AppTheme.whiteColor,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _buildContent(),
        ),
      );
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
              )
            : (gradient ?? AppTheme.primaryGradient),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDisabled ? null : AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.whiteColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTheme.poppinsSemiBold(
              fontSize: 16,
              color: AppTheme.whiteColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTheme.poppinsSemiBold(
        fontSize: 18,
        color: AppTheme.whiteColor,
      ),
    );
  }
}

/// Primary action button (dark background)
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.tabBar,
          foregroundColor: AppTheme.whiteColor,
          elevation: 8,
          shadowColor: Colors.black.withAlpha(77), // 0.3 opacity
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                ),
              )
            : Text(
                text,
                style: AppTheme.poppinsSemiBold(
                  fontSize: 18,
                  color: AppTheme.whiteColor,
                ),
              ),
      ),
    );
  }
}
