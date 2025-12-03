// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingTextStyleLibrary = MockLibraryUnit(
  'lib/src/painting/text_style.dart',
  r'''
@immutable
class TextStyle {
  final bool inherit;

  final String? fontFamily;

  final double? fontSize;

  final FontWeight? fontWeight;

  final FontStyle? fontStyle;

  final double? letterSpacing;

  final double? wordSpacing;

  final TextBaseline? textBaseline;

  final double? height;

  final double? decorationThickness;

  const TextStyle({
    this.inherit = true,
    Color? color,
    Color? backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.textBaseline,
    this.height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
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
