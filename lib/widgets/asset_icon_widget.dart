import 'package:flutter/material.dart';

class AssetIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final String fileExtension;

  const AssetIconWidget({
    Key? key,
    required this.iconName,
    required this.size,
    this.fileExtension = 'png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
        'assets/icons/$iconName.$fileExtension',
        width: size,
        height: size,
        fit: BoxFit.contain, // ADD THIS - ensures uniform sizing
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.description,
            size: size,
          );
        },
      );
  }
}
