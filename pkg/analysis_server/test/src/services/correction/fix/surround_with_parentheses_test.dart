// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SurroundWithParenthesesTest);
  });
}

@reflectiveTest
class SurroundWithParenthesesTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.SURROUND_WITH_PARENTHESES;

  Future<void> test_cast_cast() async {
    await resolveTestCode('''
void f(x) {
  switch (x) {
    case 0 as int as num:
      break;
  }
}
''');
    await assertHasFix('''
void f(x) {
  switch (x) {
    case (0 as int) as num:
      break;
  }
}
''');
  }

  Future<void> test_cast_nullCheck() async {
    await resolveTestCode('''
void f(x) {
  switch (x) {
    case 0 as int? ?:
      break;
  }
}
''');
    await assertHasFix('''
void f(x) {
  switch (x) {
    case (0 as int?) ?:
      break;
  }
}
''');
  }

  Future<void> test_relationalNullCheck() async {
    await resolveTestCode('''
void f(x) {
  switch (x) {
    case > 1?:
      break;
  }
}
''');
    await assertHasFix('''
void f(x) {
  switch (x) {
    case (> 1)?:
      break;
  }
}
''');
  }
}
