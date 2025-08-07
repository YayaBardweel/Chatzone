
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';


enum LoadingType { circular, linear, dots, pulse }

class LoadingWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.message,
    this.color,
    this.size = 50.0,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingIndicator(),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: widget.color ?? AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularLoader();
      case LoadingType.linear:
        return _buildLinearLoader();
      case LoadingType.dots:
        return _buildDotsLoader();
      case LoadingType.pulse:
        return _buildPulseLoader();
    }
  }

  Widget _buildCircularLoader() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color ?? AppColors.primary,
        ),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildLinearLoader() {
    return SizedBox(
      width: widget.size * 2,
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDotsLoader() {
    return SizedBox(
      width: widget.size,
      height: widget.size / 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              final animationValue = (_dotsController.value - (index * 0.2))
                  .clamp(0.0, 1.0);
              return Transform.scale(
                scale: 0.5 + (0.5 * animationValue),
                child: Container(
                  width: widget.size / 8,
                  height: widget.size / 8,
                  decoration: BoxDecoration(
                    color: (widget.color ?? AppColors.primary)
                        .withOpacity(0.5 + (0.5 * animationValue)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseLoader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _controller.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: (widget.color ?? AppColors.primary)
                  .withOpacity(0.3 + (0.4 * (1 - _controller.value))),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: widget.color ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}