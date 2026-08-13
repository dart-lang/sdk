// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseFullHexValuesForFlutterColorsTest);
  });
}

@reflectiveTest
class UseFullHexValuesForFlutterColorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_full_hex_values_for_flutter_colors;

  test_decimal() async {
    await assertDiagnosticsFromMarkup(r'''
library dart.ui;

var c = Color([!1!]);

class Color {
  Color(int v);
}
''');
  }

  test_dynamicArgument() async {
    await assertNoDiagnostics(r'''
library dart.ui;

dynamic a = 1;
var c = Color(a);

class Color {
  Color(int v);
}
''');
  }

  test_eightDigitHex_lower() async {
    await assertNoDiagnostics(r'''
library dart.ui;

var c = Color(0x00000000);

class Color {
  Color(int v);
}
''');
  }

  test_eightDigitHex_upper() async {
    await assertNoDiagnostics(r'''
library dart.ui;

var c = Color(0X00000000);

class Color {
  Color(int v);
}
''');
  }

  test_sixDigitHex_lower() async {
    await assertDiagnosticsFromMarkup(r'''
library dart.ui;

var c = Color([!0x000000!]);

class Color {
  Color(int v);
}
''');
  }

  test_sixDigitHex_upper() async {
    await assertDiagnosticsFromMarkup(r'''
library dart.ui;

var c = Color([!0X000000!]);

class Color {
  Color(int v);
}
''');
  }

  test_sixDigitHex_withSeparators() async {
    await assertDiagnosticsFromMarkup(r'''
library dart.ui;

var c = Color([!0x00_00_00!]);

class Color {
  Color(int v);
}
''');
  }
}
