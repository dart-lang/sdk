// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToConstantPatternPatternTest);
  });
}

@reflectiveTest
class ConvertToConstantPatternPatternTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_CONSTANT_PATTERN;

  @override
  String get lintCode => LintNames.type_literal_in_constant_pattern;

  Future<void> test_constType_matchObject() async {
    await resolveTestCode('''
void f(Object x) {
  if (x case int) {}
}
''');
    await assertHasFix('''
void f(Object x) {
  if (x case const (int)) {}
}
''');
  }

  Future<void> test_constType_matchType() async {
    await resolveTestCode('''
void f(Type x) {
  if (x case int) {}
}
''');
    await assertHasFix('''
void f(Type x) {
  if (x case const (int)) {}
}
''');
  }

  Future<void> test_constType_matchType_withImportPrefix() async {
    await resolveTestCode('''
import 'dart:math' as math;
void f(Type x) {
  if (x case math.Random) {}
}
''');
    await assertHasFix('''
import 'dart:math' as math;
void f(Type x) {
  if (x case const (math.Random)) {}
}
''');
  }
}
