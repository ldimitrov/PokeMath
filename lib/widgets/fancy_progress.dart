import 'package:flutter/material.dart';

/// Abgerundeter Fortschrittsbalken mit Farbverlauf, Glanzlicht und
/// weicher Animation bei Wertänderungen.
class FancyProgressBar extends StatelessWidget {
  final double value; // 0.0 .. 1.0
  final List<Color> colors;
  final double height;

  const FancyProgressBar({
    super.key,
    required this.value,
    required this.colors,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.last.withValues(alpha: 0.15),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, animated, _) => Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: animated,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: radius,
              ),
              // Glanzlicht oben für einen leicht "bonbonartigen" Look.
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.45,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: height / 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
