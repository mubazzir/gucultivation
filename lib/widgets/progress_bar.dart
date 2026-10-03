import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CultivationProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? color;

  const CultivationProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color ?? AppTheme.accentDark,
                  color ?? AppTheme.accent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
