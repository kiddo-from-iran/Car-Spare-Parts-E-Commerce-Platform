import 'package:flutter/material.dart';

Widget buildMapEmbed({required double height, required String url}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(
      'https://staticmap.openstreetmap.de/staticmap.php?center=35.8242,50.9910&zoom=14&size=800x400&markers=35.8242,50.9910,red-pushpin',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        alignment: Alignment.center,
        child: const Icon(Icons.map_outlined, size: 48),
      ),
    ),
  );
}
