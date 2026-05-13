import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A text field that masks its content by default and reveals on toggle.
class MaskedField extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool initiallyRevealed;

  MaskedField({
    super.key,
    required this.label,
    required this.value,
    this.onCopy,
    this.initiallyRevealed = false,
  });

  @override
  State<MaskedField> createState() => _MaskedFieldState();
}

class _MaskedFieldState extends State<MaskedField> {
  late bool _revealed;

  @override
  void initState() {
    super.initState();
    _revealed = widget.initiallyRevealed;
  }

  String get _maskedValue {
    if (_revealed) return widget.value;
    return '•' * widget.value.length.clamp(8, 20);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.of(context).textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _maskedValue,
                  style: TextStyle(
                    fontSize: 15,
                    color: _revealed
                        ? AppColors.of(context).textPrimary
                        : AppColors.of(context).textSecondary,
                    fontFamily: _revealed ? null : 'monospace',
                    letterSpacing: _revealed ? 0 : 2,
                  ),
                ),
              ],
            ),
          ),
          // Reveal/hide toggle
          IconButton(
            icon: Icon(
              _revealed ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: AppColors.of(context).textSecondary,
            ),
            onPressed: () => setState(() => _revealed = !_revealed),
            tooltip: _revealed ? 'Hide' : 'Reveal',
          ),
          // Copy button
          if (widget.onCopy != null)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 20,
                color: AppColors.accentCyan,
              ),
              onPressed: widget.onCopy,
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }
}
