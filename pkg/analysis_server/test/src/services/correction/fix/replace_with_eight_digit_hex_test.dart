// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithEightDigitHexTest);
    defineReflectiveTests(ReplaceWithEightDigitHexBulkTest);
  });
}

@reflectiveTest
class ReplaceWithEightDigitHexBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_full_hex_values_for_flutter_colors;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(1);
var c2 = Color(0x000001);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0x00000001);
var c2 = Color(0x00000001);

class Color {
  Color(int value);
}
''');
  }
}

@reflectiveTest
class ReplaceWithEightDigitHexTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithEightDigitHex;

  @override
  String get lintCode => LintNames.use_full_hex_values_for_flutter_colors;

  Future<void> test_decimal() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(1);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0x00000001);

class Color {
  Color(int value);
}
''');
  }

  Future<void> test_sixDigitHex() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(0x000001);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0x00000001);

class Color {
  Color(int value);
}
''');
  }

  Future<void> test_sixDigitHex_capitalX() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(0X000001);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0X00000001);

class Color {
  Color(int value);
}
''');
  }

  Future<void> test_sixDigitHex_withIrregularSeparators() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(0x000__001);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0x00000__001);

class Color {
  Color(int value);
}
''');
  }

  Future<void> test_sixDigitHex_withTripletSeparators() async {
    await resolveTestCode('''
library dart.ui;

var c = Color(0x00_00_01);

class Color {
  Color(int value);
}
''');
    await assertHasFix('''
library dart.ui;

var c = Color(0x00_00_00_01);

class Color {
  Color(int value);
}
''');
  }
}
