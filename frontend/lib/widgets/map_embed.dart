import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import 'map_platform_stub.dart' if (dart.library.html) 'map_platform_web.dart' as platform;

/// Google Maps preview (iframe on web, static map elsewhere).
class MapEmbed extends StatelessWidget {
  const MapEmbed({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return platform.buildMapEmbed(height: height, url: AppAssets.mapEmbedUrl);
  }
}
