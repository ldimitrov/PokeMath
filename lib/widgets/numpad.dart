import 'package:flutter/material.dart';

/// Großer kindgerechter Ziffernblock mit Löschen- und OK-Taste.
class Numpad extends StatelessWidget {
  final void Function(int digit) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final bool submitEnabled;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
    this.submitEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget key(Widget child, VoidCallback? onTap, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: color ?? scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(height: 60, child: Center(child: child)),
          ),
        ),
      );
    }

    Widget digit(int d) => Expanded(
          child: key(
            Text('$d',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            () => onDigit(d),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [digit(1), digit(2), digit(3)]),
        Row(children: [digit(4), digit(5), digit(6)]),
        Row(children: [digit(7), digit(8), digit(9)]),
        Row(children: [
          Expanded(
            child: key(
                Icon(Icons.backspace_outlined, color: scheme.error), onDelete,
                color: scheme.errorContainer.withValues(alpha: 0.5)),
          ),
          digit(0),
          Expanded(
            child: key(
              Icon(Icons.check,
                  size: 32,
                  color: submitEnabled
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.3)),
              submitEnabled ? onSubmit : null,
              color: submitEnabled
                  ? Colors.green
                  : scheme.surfaceContainerHighest,
            ),
          ),
        ]),
      ],
    );
  }
}
