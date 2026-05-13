import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  const TVButton({super.key, required this.child, required this.onTap, this.borderRadius = 15});
  
  @override State<TVButton> createState() => _TVButtonState();
}

class _TVButtonState extends State<TVButton> {
  bool _isF = false;
  
  @override Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isF = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap(); return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: _isF ? Colors.red : Colors.transparent, width: 3.0),
            boxShadow: _isF ? [BoxShadow(color: Colors.red.withOpacity(0.7), blurRadius: 15)] : [],
          ),
          transform: _isF ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}
