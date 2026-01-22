// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

class MaterialColor extends ColorSwatch<int> {
  const MaterialColor(int primary, Map<int, Color> swatch)
    : super(primary, swatch);

  Color get shade100 => this[100];

  Color get shade200 => this[200];

  Color get shade300 => this[300];

  Color get shade400 => this[400];

  Color get shade50 => this[50];

  Color get shade500 => this[500];

  Color get shade600 => this[600];

  Color get shade700 => this[700];

  Color get shade800 => this[800];

  Color get shade900 => this[900];
}

class MaterialAccentColor extends ColorSwatch<int> {
  const MaterialAccentColor(int primary, Map<int, Color> swatch)
    : super(primary, swatch);

  Color get shade50 => this[50];

  Color get shade100 => this[100];

  Color get shade200 => this[200];

  Color get shade400 => this[400];

  Color get shade700 => this[700];
}

class Colors {
  Colors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const MaterialColor red = MaterialColor(_redPrimaryValue, <int, Color>{
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFFCDD2),
    200: Color(0xFFEF9A9A),
    300: Color(0xFFE57373),
    400: Color(0xFFEF5350),
    500: Color(_redPrimaryValue),
    600: Color(0xFFE53935),
    700: Color(0xFFD32F2F),
    800: Color(0xFFC62828),
    900: Color(0xFFB71C1C),
  });
  static const int _redPrimaryValue = 0xFFF44336;

  static const MaterialAccentColor redAccent =
      MaterialAccentColor(_redAccentValue, <int, Color>{
        100: Color(0xFFFF8A80),
        200: Color(_redAccentValue),
        400: Color(0xFFFF1744),
        700: Color(0xFFD50000),
      });
  static const int _redAccentValue = 0xFFFF5252;
}
