import 'package:flutter/material.dart';

class AssetIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final String fileExtension;
  final Color? color; // Add color parameter

  const AssetIconWidget({
    Key? key,
    required this.iconName,
    required this.size,
    this.fileExtension = 'png',
    this.color, // Optional color parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: Image.asset(
        'assets/icons/$iconName.$fileExtension',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.description,
            size: size,
            color: color, // Apply color to fallback icon too
          );
        },
      ),
    );
  }
}
