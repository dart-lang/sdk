// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReadWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReadWriteTest extends PubPackageResolutionTest {
  @override
  bool get retainDataForTesting => true;

  test_final_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  x;
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_read_prefixNegate() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  -x;
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  x += 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x +=', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  x++;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x++', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  ++x;
//  ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  x = 0;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x =', assigned: true, unassigned: false);
  }

  test_final_definitelyAssigned_write_forEachLoop_identifier() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
void f(final x) {
  for (x in [0, 1, 2]) {
//     ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
    x;
  }
}
''');
    _assertAssigned('x in', assigned: true, unassigned: false);
  }

  test_final_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final x;
  x; // 0
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
  x();
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
    _assertAssigned('x()', assigned: false, unassigned: true);
  }

  test_final_definitelyUnassigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  x += 1;
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: true);
  }

  test_final_definitelyUnassigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  x++;
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
}
''');
    _assertAssigned('x++', assigned: false, unassigned: true);
  }

  test_final_definitelyUnassigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  ++x; // 0
//  ^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_final_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  final x;
  x = 0;
}
''');
    _assertAssigned('x = 0', assigned: false, unassigned: true);
  }

  test_final_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  final x;
  if (b) x = 0;
  x; // 0
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_final_neither_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  final x;
  if (b) x = 0;
  x += 1;
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: false);
  }

  test_final_neither_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  final x;
  if (b) x = 0;
  x++;
//^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x++', assigned: false, unassigned: false);
  }

  test_final_neither_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  final x;
  if (b) x = 0;
  ++x; // 0
//  ^
// [diag.readPotentiallyUnassignedFinal] The final variable 'x' can't be read because it's potentially unassigned at this point.
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_final_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  final x;
  if (b) x = 0;
  x = 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x = 0;
  x += 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x +=', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x = 0;
  x++;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x++', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x = 0;
  ++x; // 0
//  ^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x = 0;
  x = 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x = 1', assigned: true, unassigned: false);
  }

  test_lateFinal_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinal_definitelyUnassigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x += 1;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: true);
  }

  test_lateFinal_definitelyUnassigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x++;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x++', assigned: false, unassigned: true);
  }

  test_lateFinal_definitelyUnassigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  ++x; // 0
//  ^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinal_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final x;
  x = 0;
}
''');
    _assertAssigned('x =', assigned: false, unassigned: true);
  }

  test_lateFinal_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  late final x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinal_neither_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final x;
  if (b) x = 0;
  x += 1;
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: false);
  }

  test_lateFinal_neither_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final x;
  if (b) x = 0;
  x++;
}
''');
    _assertAssigned('x++', assigned: false, unassigned: false);
  }

  test_lateFinal_neither_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final x;
  if (b) x = 0;
  ++x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinal_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final x;
  if (b) x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final int? x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x = 0;
  x += 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x +=', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x = 0;
  x++;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x++', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x = 0;
  ++x; // 0
//  ^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x = 0;
  x = 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x = 1', assigned: true, unassigned: false);
  }

  test_lateFinalNullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final int? x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_definitelyUnassigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x += 1;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
//  ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_definitelyUnassigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x++;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
    _assertAssigned('x++', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_definitelyUnassigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  ++x; // 0
//^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
//  ^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late final int? x;
  x = 0;
}
''');
    _assertAssigned('x = 0', assigned: false, unassigned: true);
  }

  test_lateFinalNullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  late final int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_neither_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final int? x;
  if (b) x = 0;
  x += 1;
//  ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_neither_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final int? x;
  if (b) x = 0;
  x++;
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
    _assertAssigned('x++', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_neither_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final int? x;
  if (b) x = 0;
  ++x; // 0
//^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinalNullable_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late final int? x;
  if (b) x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) {
  late final T x;
  x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t, T t2) {
  // ignore:unused_local_variable
  late final T x;
  x = t;
  x = t2;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
}
''');
    _assertAssigned('x = t2', assigned: true, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>() {
  late final T x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateFinalPotentiallyNonNullable_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) {
  // ignore:unused_local_variable
  late final T x;
  x = t;
}
''');
    _assertAssigned('x = t', assigned: false, unassigned: true);
  }

  test_lateFinalPotentiallyNonNullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(bool b, T t) {
  late final T x;
  if (b) x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateFinalPotentiallyNonNullable_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(bool b, T t, T t2) {
  // ignore:unused_local_variable
  late final T x;
  if (b) x = t;
  x = t2;
}
''');
    _assertAssigned('x = t2', assigned: false, unassigned: false);
  }

  test_lateNullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int? x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateNullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int? x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateNullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  late int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_latePotentiallyNonNullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) {
  late T x;
  x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_latePotentiallyNonNullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>() {
  late T x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_latePotentiallyNonNullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(bool b, T t) {
  late T x;
  if (b) x = t;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateVar_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late var x;
  x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyAssigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late var x;
  x = 0;
  x += 1;
}
''');
    _assertAssigned('x +=', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyAssigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late var x;
  x = 0;
  x++;
}
''');
    _assertAssigned('x++', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyAssigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late var x;
  x = 0;
  ++x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  late var x;
  x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: true, unassigned: false);
  }

  test_lateVar_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late var x;
  x; // 0
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'x' is definitely unassigned at this point.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_lateVar_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  late var x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateVar_neither_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late var x;
  if (b) x = 0;
  x += 1;
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: false);
  }

  test_lateVar_neither_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late var x;
  if (b) x = 0;
  x++;
}
''');
    _assertAssigned('x++', assigned: false, unassigned: false);
  }

  test_lateVar_neither_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late var x;
  if (b) x = 0;
  ++x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_lateVar_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  late var x;
  if (b) x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  test_notNullable_write_forEachLoop_identifier() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int x;
  for (x in [0, 1, 2]) {
    x; // 0
  }
}
''');
    _assertAssigned('x in', assigned: false, unassigned: true);
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_nullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x;
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_nullable_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x = 0;
}
''');
    _assertAssigned('x = 0', assigned: true, unassigned: false);
  }

  test_nullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? x;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_nullable_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  int? x;
  x = 0;
}
''');
    _assertAssigned('x = 0', assigned: false, unassigned: true);
  }

  test_nullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int? x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_nullable_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  int? x;
  if (b) x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  test_potentiallyNonNullable_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: true, unassigned: false);
  }

  test_potentiallyNonNullable_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x, T t) {
  x = t;
}
''');
    _assertAssigned('x = t', assigned: true, unassigned: false);
  }

  test_potentiallyNonNullable_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>() {
  T x;
  x; // 0
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_potentiallyNonNullable_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) {
  // ignore:unused_local_variable
  T x;
  x = t;
}
''');
    _assertAssigned('x = t', assigned: false, unassigned: true);
  }

  test_potentiallyNonNullable_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(bool b, T t) {
  T x;
  if (b) x = t;
  x; // 0
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_potentiallyNonNullable_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(bool b, T t, T t2) {
  // ignore:unused_local_variable
  T x;
  if (b) x = t;
  x = t2;
}
''');
    _assertAssigned('x = t2', assigned: false, unassigned: false);
  }

  test_var_definitelyAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  x;
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_var_definitelyAssigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  x += 1;
}
''');
    _assertAssigned('x +=', assigned: true, unassigned: false);
  }

  test_var_definitelyAssigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  x++;
}
''');
    _assertAssigned('x++', assigned: true, unassigned: false);
  }

  test_var_definitelyAssigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  ++x;
}
''');
    _assertAssigned('x;', assigned: true, unassigned: false);
  }

  test_var_definitelyAssigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  x = 0;
}
''');
    _assertAssigned('x =', assigned: true, unassigned: false);
  }

  test_var_definitelyUnassigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var x;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_var_definitelyUnassigned_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  var x;
  x += 0;
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: true);
  }

  test_var_definitelyUnassigned_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  var x;
  x++;
}
''');
    _assertAssigned('x++', assigned: false, unassigned: true);
  }

  test_var_definitelyUnassigned_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  var x;
  ++x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: true);
  }

  test_var_definitelyUnassigned_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  var x;
  x = 0;
}
''');
    _assertAssigned('x = 0', assigned: false, unassigned: true);
  }

  test_var_neither_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  var x;
  if (b) x = 0;
  x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_var_neither_readWrite_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  var x;
  if (b) x = 0;
  x += 1;
}
''');
    _assertAssigned('x +=', assigned: false, unassigned: false);
  }

  test_var_neither_readWrite_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  var x;
  if (b) x = 0;
  ++x; // 0
}
''');
    _assertAssigned('x; // 0', assigned: false, unassigned: false);
  }

  test_var_neither_readWrite_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  var x;
  if (b) x = 0;
  x++;
}
''');
    _assertAssigned('x++', assigned: false, unassigned: false);
  }

  test_var_neither_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  // ignore:unused_local_variable
  var x;
  if (b) x = 0;
  x = 1;
}
''');
    _assertAssigned('x = 1', assigned: false, unassigned: false);
  }

  void _assertAssigned(
    String search, {
    required bool assigned,
    required bool unassigned,
  }) {
    var node = findNode.simple(search);

    var testingData = driverFor(testFile).testingData!;
    var unitData = testingData.uriToFlowAnalysisData[result.uri]!;

    if (assigned) {
      expect(unitData.definitelyAssigned, contains(node));
    } else {
      expect(unitData.notDefinitelyAssigned, contains(node));
      expect(unitData.definitelyAssigned, isNot(contains(node)));
    }

    if (unassigned) {
      expect(unitData.definitelyUnassigned, contains(node));
    } else {
      expect(unitData.definitelyUnassigned, isNot(contains(node)));
    }
  }
}
