// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReadWriteWithNullSafetyTest);
  });
}

@reflectiveTest
class ReadWriteWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  @override
  bool get retainDataForTesting => true;

  test_final_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  final x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_read_prefixNegate() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  x = 0;
  -x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_write_assignment_simple() async {
    await assertErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  x = 0;
  x = 1;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 67, 1),
    ]);
    _assertAssigned('x = 0', assigned: false, unassigned: true);
    _assertAssigned('x = 1', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_write_forEachLoop_identifier() async {
    await assertErrorsInCode(r'''
void f() {
  final x = 0;
  for (x in [0, 1, 2]) {
    x;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 33, 1),
    ]);
    _assertAssigned('x in', assigned: true, unassigned: false);
  }

  test_final_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  final x;
  x; // 0
  x();
}
''', [
      error(CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL, 24, 1),
      error(CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL, 34, 1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
    _assertAssigned('x()', assigned: false, unassigned: true);
  }

  test_final_neither_read() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  final x;
  if (b) x = 0;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL, 46, 1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  late final x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  late final x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 29,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinal_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  late var x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  late final int? x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  late final int? x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 34,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  late final int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) {
  late final T x;
  x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f<T>() {
  late final T x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 34,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinalPotentiallyNonNullable_neither_read() async {
    await assertNoErrorsInCode(r'''
void f<T>(bool b, T t) {
  late final T x;
  if (b) x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateNullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  late int? x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateNullable_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  late int? x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 28,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateNullable_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  late int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_latePotentiallyNonNullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) {
  late T x;
  x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_latePotentiallyNonNullable_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f<T>() {
  late T x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 28,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_latePotentiallyNonNullable_neither_read() async {
    await assertNoErrorsInCode(r'''
void f<T>(bool b, T t) {
  late T x;
  if (b) x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateVar_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  late var x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  late var x;
  x; // 0
}
''', [
      error(CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, 27,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateVar_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  late var x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_notNullable_write_forEachLoop_identifier() async {
    await assertNoErrorsInCode(r'''
void f() {
  int x;
  for (x in [0, 1, 2]) {
    x; // 0
  }
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_nullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_nullable_definitelyUnassigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  int? x;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_nullable_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_potentiallyNonNullable_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f<T>(T x) {
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_potentiallyNonNullable_definitelyUnassigned_read() async {
    await assertErrorsInCode(r'''
void f<T>() {
  T x;
  x; // 0
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          23,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_potentiallyNonNullable_neither_read() async {
    await assertErrorsInCode(r'''
void f<T>(bool b, T t) {
  T x;
  if (b) x = t;
  x; // 0
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          50,
          1),
    ]);
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_var_definitelyAssigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  var x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_var_definitelyUnassigned_read() async {
    await assertNoErrorsInCode(r'''
void f() {
  var x;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_var_neither_read() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  var x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  void _assertAssigned(
    String search, {
    @required bool assigned,
    @required bool unassigned,
  }) {
    var node = findNode.simple(search);

    var testingData = driverFor(testFilePath).testingData;
    var unitData = testingData.uriToFlowAnalysisData[result.uri];

    if (assigned) {
      expect(unitData.definitelyAssignedNodes, contains(node));
    } else {
      expect(unitData.definitelyAssignedNodes, isNot(contains(node)));
    }

    if (unassigned) {
      expect(unitData.definitelyUnassignedNodes, contains(node));
    } else {
      expect(unitData.definitelyUnassignedNodes, isNot(contains(node)));
    }
  }
}
