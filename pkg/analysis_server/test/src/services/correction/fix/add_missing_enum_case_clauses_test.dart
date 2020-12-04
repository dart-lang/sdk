// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
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

  bool Function(AnalysisError) get _filter {
    var hasError = false;
    return (error) {
      if (!hasError &&
          error.errorCode ==
              StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH) {
        hasError = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixWithFilter(String expected) async {
    await assertHasFix(expected, errorFilter: _filter);
  }

  Future<void> test_empty() async {
    await resolveTestCode('''
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

  Future<void> test_incomplete_switchStatement() async {
    await resolveTestCode(r'''
enum E {a, b, c}

void f(E e) {
  switch(e
}
''');
    await assertNoFix(errorFilter: _filter);
  }

  Future<void> test_nonEmpty() async {
    await resolveTestCode('''
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
