import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  
  const ShimmerLoading({super.key, required this.child, required this.isLoading});
  
  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    
    return Shimmer(
      linearGradient: const LinearGradient(
        colors: [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF1F2937)],
        stops: [0.0, 0.5, 1.0],
      ),
      child: child,
    );
  }
}

class Shimmer extends StatefulWidget {
  final LinearGradient linearGradient;
  final Widget child;
  
  const Shimmer({super.key, required this.linearGradient, required this.child});
  
  @override State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShimmerLoadingWidget(
        linearGradient: widget.linearGradient,
        animation: _animation,
        child: widget.child,
      ),
    );
  }
}

class ShimmerLoadingWidget extends StatelessWidget {
  final LinearGradient linearGradient;
  final Animation<double> animation;
  final Widget child;
  
  const ShimmerLoadingWidget({
    super.key,
    required this.linearGradient,
    required this.animation,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return linearGradient.createShader(
          Rect.fromLTRB(
            bounds.width * animation.value - bounds.width,
            0,
            bounds.width * animation.value,
            bounds.height,
          ),
        );
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}
