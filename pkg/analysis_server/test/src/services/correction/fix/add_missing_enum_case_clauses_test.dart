// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingEnumCaseClausesTest);
  });
}

@reflectiveTest
class AddMissingEnumCaseClausesTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  Future<void> assertHasFixWithFilter(String expected) async {
    var noError = true;
    await assertHasFix(expected, errorFilter: (error) {
      if (noError &&
          error.errorCode ==
              StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH) {
        noError = false;
        return true;
      }
      return false;
    });
  }

  Future<void> test_empty() async {
    await resolveTestUnit('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_nonEmpty() async {
    await resolveTestUnit('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }
}
