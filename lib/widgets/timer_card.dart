import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TimerCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
