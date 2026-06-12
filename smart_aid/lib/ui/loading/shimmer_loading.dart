import 'package:flutter/material.dart';

/// A reusable, lightweight skeleton widget for calm loading states.
/// Replaces harsh CircularProgressIndicators with a subtle breathing animation.
class SkeletonCard extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const SkeletonCard({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 15.0,
    this.margin = const EdgeInsets.only(bottom: 12.0),
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // A slow, calming breathing effect (800ms) instead of a rapid flash.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        width: widget.width,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
