// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final cupertinoColorsLibrary = MockLibraryUnit(
  'lib/src/cupertino/colors.dart',
  r'''
import 'dart:ui';

import '../../foundation.dart';

abstract final class CupertinoColors {
  static const CupertinoDynamicColor activeBlue = systemBlue;

  static const Color black = Color(0xFF000000);

  static const Color white = Color(0xFFFFFFFF);

  static const CupertinoDynamicColor systemBlue =
      CupertinoDynamicColor.withBrightnessAndContrast(
        debugLabel: 'systemBlue',
        color: Color.fromARGB(255, 0, 122, 255),
        darkColor: Color.fromARGB(255, 10, 132, 255),
        highContrastColor: Color.fromARGB(255, 0, 64, 221),
        darkHighContrastColor: Color.fromARGB(255, 64, 156, 255),
      );
}

@immutable
class CupertinoDynamicColor with Diagnosticable implements Color {
  const CupertinoDynamicColor({
    String? debugLabel,
    required Color color,
    required Color darkColor,
    required Color highContrastColor,
    required Color darkHighContrastColor,
    required Color elevatedColor,
    required Color darkElevatedColor,
    required Color highContrastElevatedColor,
    required Color darkHighContrastElevatedColor,
  }) : this._(
         color,
         color,
         darkColor,
         highContrastColor,
         darkHighContrastColor,
         elevatedColor,
         darkElevatedColor,
         highContrastElevatedColor,
         darkHighContrastElevatedColor,
         null,
         debugLabel,
       );

  const CupertinoDynamicColor.withBrightnessAndContrast({
    String? debugLabel,
    required Color color,
    required Color darkColor,
    required Color highContrastColor,
    required Color darkHighContrastColor,
  }) : this(
         debugLabel: debugLabel,
         color: color,
         darkColor: darkColor,
         highContrastColor: highContrastColor,
         darkHighContrastColor: darkHighContrastColor,
         elevatedColor: color,
         darkElevatedColor: darkColor,
         highContrastElevatedColor: highContrastColor,
         darkHighContrastElevatedColor: darkHighContrastColor,
       );

  const CupertinoDynamicColor.withBrightness({
    String? debugLabel,
    required Color color,
    required Color darkColor,
  }) : this(
         debugLabel: debugLabel,
         color: color,
         darkColor: darkColor,
         highContrastColor: color,
         darkHighContrastColor: darkColor,
         elevatedColor: color,
         darkElevatedColor: darkColor,
         highContrastElevatedColor: color,
         darkHighContrastElevatedColor: darkColor,
       );

  const CupertinoDynamicColor._(
    Color _effectiveColor,
    this.color,
    this.darkColor,
    this.highContrastColor,
    this.darkHighContrastColor,
    this.elevatedColor,
    this.darkElevatedColor,
    this.highContrastElevatedColor,
    this.darkHighContrastElevatedColor,
    Element? _debugResolveContext,
    String? _debugLabel,
  );

  @override
  int get value => throw 0;

  final Color color;

  final Color darkColor;

  final Color highContrastColor;

  final Color darkHighContrastColor;

  final Color elevatedColor;

  final Color darkElevatedColor;

  final Color highContrastElevatedColor;

  final Color darkHighContrastElevatedColor;
}
''',
);
