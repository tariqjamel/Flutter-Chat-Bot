import 'package:flutter/material.dart';

class Waveform extends StatefulWidget {
  @override
  _WaveformState createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return BouncingCircle(delay: index * 200);
      }),
    );
  }
}

class BouncingCircle extends StatefulWidget {
  final int delay;

  BouncingCircle({required this.delay});

  @override
  _BouncingCircleState createState() => _BouncingCircleState();
}

class _BouncingCircleState extends State<BouncingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curvedAnimation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            widget.delay / 1000,
            1.0,
            curve: Curves.easeInOut,
          ),
        );

        return Transform.translate(
          offset: Offset(0, -150 * (0.5 * (1 - (curvedAnimation.value - 0.5).abs()))),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
