import 'dart:typed_data';

import 'package:flutter/material.dart';

class AppIconImage extends StatelessWidget {
  const AppIconImage({super.key, required this.bytes, this.size = 40});

  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    if (image == null || image.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: const Icon(Icons.apps),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
