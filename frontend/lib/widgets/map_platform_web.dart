// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

bool _registered = false;

Widget buildMapEmbed({required double height, required String url}) {
  if (!_registered) {
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      'jahangiri-map-embed',
      (int viewId) => html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true,
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: const HtmlElementView(viewType: 'jahangiri-map-embed'),
    ),
  );
}
