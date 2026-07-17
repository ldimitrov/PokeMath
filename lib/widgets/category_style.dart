import 'package:flutter/material.dart';

import '../logic/exercise_generator.dart';

/// Freundliche Akzentfarbe pro Aufgaben-Kategorie.
extension ExerciseTypeStyle on ExerciseType {
  Color get color => switch (this) {
        ExerciseType.plusMinus => const Color(0xFFF57C00), // Orange
        ExerciseType.zehner => const Color(0xFF1E88E5), // Blau
        ExerciseType.fehlend => const Color(0xFF00897B), // Petrol
        ExerciseType.kette => const Color(0xFF8E24AA), // Lila
        ExerciseType.korrektFalsch => const Color(0xFF43A047), // Grün
        ExerciseType.nachbar => const Color(0xFFE53935), // Rot
        ExerciseType.folge => const Color(0xFF3949AB), // Indigo
      };

  /// Zarter Hintergrund für Kacheln.
  Color get tileColor => Color.alphaBlend(color.withValues(alpha: 0.14),
      const Color(0xFFFFFDFB));
}
