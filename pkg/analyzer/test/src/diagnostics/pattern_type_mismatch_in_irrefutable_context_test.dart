// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternTypeMismatchInIrrefutableContextTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternTypeMismatchInIrrefutableContextTest
    extends PubPackageResolutionTest {
  test_assignedVariablePattern_recordDestruction_hasCall() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int Function(int) a, (A,) x) {
  (a) = x;
// ^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type '(A,)' isn't assignable to the required type 'int Function(int)'.
}

class A {
  int call(int x) => x;
}
''');
  }

  test_assignedVariablePattern_valueDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a, dynamic x) {
  (a) = x;
}
''');
  }

  test_assignedVariablePattern_valueSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num a, int x) {
  (a) = x;
}
''');
  }

  test_assignedVariablePattern_valueSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a, num x) {
  (a) = x;
// ^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'num' isn't assignable to the required type 'int'.
}
''');
  }

  test_declaredVariablePattern_recordDestruction_hasCall() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((A,) x) {
  var (int Function(int) v,) = x;
//     ^^^^^^^^^^^^^^^^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'A' isn't assignable to the required type 'int Function(int)'.
//                       ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}

class A {
  int call(int x) => x;
}
''');
  }

  test_declaredVariablePattern_valueDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  var (int a) = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_declaredVariablePattern_valueSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  var (num a) = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_declaredVariablePattern_valueSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  var (int a) = x;
//     ^^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'num' isn't assignable to the required type 'int'.
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_listPattern_differentList() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<Object> x) {
  var <int>[a] = x;
//    ^^^^^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'List<Object>' isn't assignable to the required type 'List<int>'.
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_listPattern_notList() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  var [a] = x;
//    ^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'Object' isn't assignable to the required type 'List<Object?>'.
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_mapPattern_notMap() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  var <int, String>{0: a} = x;
//    ^^^^^^^^^^^^^^^^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'Object' isn't assignable to the required type 'Map<int, String>'.
//                     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_objectPattern_differentClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  var String(length: a) = x;
//    ^^^^^^^^^^^^^^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'Object' isn't assignable to the required type 'String'.
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_patternAssignment_assignedVariablePattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  (a) = 1.2;
// ^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'double' isn't assignable to the required type 'int'.
}
''');
  }

  test_recordPattern_notRecord() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  var (a,) = x;
//    ^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'Object' isn't assignable to the required type '(Object?,)'.
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_recordPattern_record_differentShape() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  var (a,) = x;
//    ^^^^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type '({int foo})' isn't assignable to the required type '(Object?,)'.
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }
}
