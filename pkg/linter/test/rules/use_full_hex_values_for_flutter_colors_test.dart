// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseFullHexValuesForFlutterColorsTest);
  });
}

@reflectiveTest
class UseFullHexValuesForFlutterColorsTest extends LintRuleTest {
  @override
  String get lintRule => 'use_full_hex_values_for_flutter_colors';

  test_dynamicArgument() async {
    await assertNoDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f(dynamic a) {
  Color(a);
}
''');
  }

  test_eightDigitHex_lower() async {
    await assertNoDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f() {
  Color(0x00000000);
}
''');
  }

  test_eightDigitHex_upper() async {
    await assertNoDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f() {
  Color(0X00000000);
}
''');
  }

  test_nonHex() async {
    await assertDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f() {
  Color(1);
}
''', [
      lint(70, 1),
    ]);
  }

  test_sixDigitHex_lower() async {
    await assertDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f() {
  Color(0x000000);
}
''', [
      lint(70, 8),
    ]);
  }

  test_sixDigitHex_upper() async {
    await assertDiagnostics(r'''
library dart.ui;

class Color {
  Color(int v);
}

void f() {
  Color(0X000000);
}
''', [
      lint(70, 8),
    ]);
  }
}
