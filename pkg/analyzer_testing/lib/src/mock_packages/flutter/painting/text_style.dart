// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingTextStyleLibrary = MockLibraryUnit(
  'lib/src/painting/text_style.dart',
  r'''
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'colors.dart';
import 'text_painter.dart';

@immutable
class TextStyle {
  final bool inherit;

  final String? fontFamily;

  final double? fontSize;

  final ui.FontWeight? fontWeight;

  final ui.FontStyle? fontStyle;

  final double? letterSpacing;

  final double? wordSpacing;

  final ui.TextBaseline? textBaseline;

  final double? height;

  final double? decorationThickness;

  const TextStyle({
    this.inherit = true,
    ui.Color? color,
    ui.Color? backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.textBaseline,
    this.height,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    ui.Paint? foreground,
    ui.Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    this.decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) : fontFamily = package == null
           ? fontFamily
           : 'packages/$package/$fontFamily',
       _fontFamilyFallback = fontFamilyFallback,
       _package = package,
       assert(color == null || foreground == null, _kColorForegroundWarning),
       assert(
         backgroundColor == null || background == null,
         _kColorBackgroundWarning,
       );
}
''',
);
