import 'dart:math';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;

  const ParticleBackground({
    super.key,
    required this.child,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _createParticles();
  }

  void _createParticles() {
    final random = Random(42);

    for (int i = 0; i < 32; i++) {
      _particles.add(
        _Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: 0.8 + random.nextDouble() * 1.5,
          speed: 1.0 + random.nextInt(3),
          phase: random.nextDouble() * pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(
          color: AppColors.background,
        ),

        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),

        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];

    for (final particle in particles) {
      final movement =
          sin(progress * pi * 2 * particle.speed + particle.phase);

      final x = particle.x * size.width + movement * 12;
      final y = particle.y * size.height + cos(
        progress * pi * 2 * particle.speed + particle.phase,
      ) * 8;

      points.add(Offset(x, y));
    }

    // Connection lines.
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.055)
      ..strokeWidth = 0.7;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;

        if (distance < 135) {
          final opacity = (1 - distance / 135) * 0.12;

          linePaint.color =
              AppColors.primary.withValues(alpha: opacity);

          canvas.drawLine(
            points[i],
            points[j],
            linePaint,
          );
        }
      }
    }

    // Particles.
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final particle = particles[i];

      particlePaint.color = AppColors.primary.withValues(alpha: 0.35);

      canvas.drawCircle(
        points[i],
        particle.radius,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}