// Copyright 2021 The Chromium Authors. All rights reserved.
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

  static const MaterialColor red = MaterialColor(
    _redPrimaryValue,
    <int, Color>{
      // For simpler testing, these values are not the real Flutter values
      // but just varying alphas on a primary value.
      50: Color(0x05FF0000),
      100: Color(0x10FF0000),
      200: Color(0x20FF0000),
      300: Color(0x30FF0000),
      400: Color(0x40FF0000),
      500: Color(0x50FF0000),
      600: Color(0x60FF0000),
      700: Color(0x70FF0000),
      800: Color(0x80FF0000),
      900: Color(0x90FF0000),
    },
  );
  static const int _redPrimaryValue = 0xFFFF0000;

  static const MaterialAccentColor redAccent = MaterialAccentColor(
    _redAccentValue,
    <int, Color>{
      // For simpler testing, these values are not the real Flutter values
      // but just varying alphas on a primary value.
      100: Color(0x10FFAA00),
      200: Color(0x20FFAA00),
      400: Color(0x40FFAA00),
      700: Color(0x70FFAA00),
    },
  );
  static const int _redAccentValue = 0xFFFFAA00;
}
