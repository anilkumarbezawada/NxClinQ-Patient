import 'package:flutter/material.dart';

class AiBotIcon extends StatelessWidget {
  const AiBotIcon({
    super.key,
    this.size = 24,
    this.fit = BoxFit.cover,
  });

  static const String assetPath = 'assets/icons/ai_bot.png';

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.auto_awesome_rounded,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}
