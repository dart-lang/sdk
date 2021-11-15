// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

class CupertinoColors {
  CupertinoColors._();

  static const CupertinoDynamicColor activeBlue = systemBlue;

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const CupertinoDynamicColor systemBlue =
      CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 0, 0, 0xFF),
    darkColor: Color.fromARGB(255, 0, 0, 0x99),
    highContrastColor: Color.fromARGB(255, 0, 0, 0x66),
    darkHighContrastColor: Color.fromARGB(255, 0, 0, 0x33),
  );
}

class CupertinoDynamicColor extends Color {
  const CupertinoDynamicColor({
    Color color,
    Color darkColor,
    Color highContrastColor,
    Color darkHighContrastColor,
    Color elevatedColor,
    Color darkElevatedColor,
    Color highContrastElevatedColor,
    Color darkHighContrastElevatedColor,
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
        );

  const CupertinoDynamicColor.withBrightnessAndContrast({
    Color color,
    Color darkColor,
    Color highContrastColor,
    Color darkHighContrastColor,
  }) : this(
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
    Color color,
    Color darkColor,
  }) : this(
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
    this._effectiveColor,
    this.color,
    this.darkColor,
    this.highContrastColor,
    this.darkHighContrastColor,
    this.elevatedColor,
    this.darkElevatedColor,
    this.highContrastElevatedColor,
    this.darkHighContrastElevatedColor,
  ) : super(0);

  final Color _effectiveColor;

  @override
  int get value => _effectiveColor.value;

  final Color color;
  final Color darkColor;
  final Color highContrastColor;
  final Color darkHighContrastColor;
  final Color elevatedColor;
  final Color darkElevatedColor;
  final Color highContrastElevatedColor;
  final Color darkHighContrastElevatedColor;
}
