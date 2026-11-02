import 'package:flutter/material.dart';

class PinButton extends StatelessWidget {
  const PinButton({
    super.key,
    required this.isPinned,
    required this.onPressed,
    required this.label,
    this.isSaving = false,
    this.size = 36,
  });

  final bool isPinned;
  final VoidCallback onPressed;
  final String label;
  final bool isSaving;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: isPinned,
      child: IconButton(
        tooltip: '${isPinned ? 'Unpin' : 'Pin'} $label',
        onPressed: isSaving ? null : onPressed,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.square(size),
          maximumSize: Size.square(size),
          padding: const EdgeInsets.all(6),
          backgroundColor: isPinned ? colors.primaryContainer : null,
          foregroundColor: isPinned
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        ),
        icon: isSaving
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            : Icon(
                isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 18,
              ),
      ),
    );
  }
}
