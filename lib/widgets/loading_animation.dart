import 'dart:math';
import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, left: 0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 8),
                    _buildDot(0.33),
                    const SizedBox(width: 8),
                    _buildDot(0.66),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWaveShadow(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(double delay) {
    final animValue = (_controller.value + delay) % 1.0;
    final scale = 0.6 + (0.4 * (1 - (animValue - 0.5).abs() * 2));
    final opacity = 0.5 + (0.5 * (1 - (animValue - 0.5).abs() * 2));
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildWaveShadow() {
    return SizedBox(
      width: 60,
      height: 20,
      child: CustomPaint(
        painter: WaveShadowPainter(_controller.value),
      ),
    );
  }
}

class WaveShadowPainter extends CustomPainter {
  final double animationValue;

  WaveShadowPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final waveHeight = 6.0;
    final waveLength = size.width / 2;
    
    path.moveTo(0, size.height / 2);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height / 2 + 
          waveHeight * 
          (0.5 + 0.5 * sin((x / waveLength - animationValue * 2) * pi));
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveShadowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
