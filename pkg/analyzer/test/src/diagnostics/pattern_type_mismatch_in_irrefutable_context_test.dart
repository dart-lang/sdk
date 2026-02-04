// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternTypeMismatchInIrrefutableContextTest);
  });
}

@reflectiveTest
class PatternTypeMismatchInIrrefutableContextTest
    extends PubPackageResolutionTest {
  test_assignedVariablePattern_recordDestruction_hasCall() async {
    await assertErrorsInCode(
      r'''
void f(int Function(int) a, (A,) x) {
  (a) = x;
}

class A {
  int call(int x) => x;
}
''',
      [error(diag.patternTypeMismatchInIrrefutableContext, 41, 1)],
    );
  }

  test_assignedVariablePattern_valueDynamic() async {
    await assertNoErrorsInCode(r'''
void f(int a, dynamic x) {
  (a) = x;
}
''');
  }

  test_assignedVariablePattern_valueSubtype() async {
    await assertNoErrorsInCode(r'''
void f(num a, int x) {
  (a) = x;
}
''');
  }

  test_assignedVariablePattern_valueSupertype() async {
    await assertErrorsInCode(
      r'''
void f(int a, num x) {
  (a) = x;
}
''',
      [error(diag.patternTypeMismatchInIrrefutableContext, 26, 1)],
    );
  }

  test_declaredVariablePattern_recordDestruction_hasCall() async {
    await assertErrorsInCode(
      r'''
void f((A,) x) {
  var (int Function(int) v,) = x;
}

class A {
  int call(int x) => x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 24, 19),
        error(diag.unusedLocalVariable, 42, 1),
      ],
    );
  }

  test_declaredVariablePattern_valueDynamic() async {
    await assertErrorsInCode(
      r'''
void f(dynamic x) {
  var (int a) = x;
}
''',
      [error(diag.unusedLocalVariable, 31, 1)],
    );
  }

  test_declaredVariablePattern_valueSubtype() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  var (num a) = x;
}
''',
      [error(diag.unusedLocalVariable, 27, 1)],
    );
  }

  test_declaredVariablePattern_valueSupertype() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  var (int a) = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 23, 5),
        error(diag.unusedLocalVariable, 27, 1),
      ],
    );
  }

  test_listPattern_differentList() async {
    await assertErrorsInCode(
      r'''
void f(List<Object> x) {
  var <int>[a] = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 31, 8),
        error(diag.unusedLocalVariable, 37, 1),
      ],
    );
  }

  test_listPattern_notList() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  var [a] = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 25, 3),
        error(diag.unusedLocalVariable, 26, 1),
      ],
    );
  }

  test_mapPattern_notMap() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  var <int, String>{0: a} = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 25, 19),
        error(diag.unusedLocalVariable, 42, 1),
      ],
    );
  }

  test_objectPattern_differentClass() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  var String(length: a) = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 25, 17),
        error(diag.unusedLocalVariable, 40, 1),
      ],
    );
  }

  test_patternAssignment_assignedVariablePattern() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  (a) = 1.2;
}
''',
      [error(diag.patternTypeMismatchInIrrefutableContext, 19, 1)],
    );
  }

  test_recordPattern_notRecord() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  var (a,) = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 25, 4),
        error(diag.unusedLocalVariable, 26, 1),
      ],
    );
  }

  test_recordPattern_record_differentShape() async {
    await assertErrorsInCode(
      r'''
void f(({int foo}) x) {
  var (a,) = x;
}
''',
      [
        error(diag.patternTypeMismatchInIrrefutableContext, 30, 4),
        error(diag.unusedLocalVariable, 31, 1),
      ],
    );
  }
}
