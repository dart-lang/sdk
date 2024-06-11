// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToWildcardVariableTest);
  });
}

@reflectiveTest
class ConvertToWildcardVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_WILDCARD_VARIABLE;

  Future<void> test_convertUnusedLocalVariable() async {
    await resolveTestCode('''
void f() {
  var x = '';
}
''');
    await assertHasFix('''
void f() {
  var _ = '';
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_list() async {
    await resolveTestCode('''
void f() {
  int? x, y;
  y;
}
''');
    await assertHasFix('''
void f() {
  int? _, y;
  y;
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_preWildcards() async {
    await resolveTestCode('''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var x = '';
}
''');
    await assertNoFix();
  }
}
