import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/services.dart';

@NowaGenerated()
class CategoryChip extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;

  final bool isSelected;

  final void Function(bool value) onSelected;

  @override
  State<CategoryChip> createState() {
    return _CategoryChipState();
  }
}

@NowaGenerated()
class _CategoryChipState extends State<CategoryChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (_isFocused &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onSelected(true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onSelected(true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.red.withValues(alpha: 0.7)
                : (_isFocused
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : (widget.isSelected
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1)),
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                ),
            ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: (widget.isSelected || _isFocused)
                  ? Colors.white
                  : Colors.white60,
              fontSize: 11.0,
              fontWeight: (widget.isSelected || _isFocused)
                  ? FontWeight.bold
                  : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
