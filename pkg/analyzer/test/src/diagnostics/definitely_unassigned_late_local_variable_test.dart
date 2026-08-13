// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitelyUnassignedLateLocalVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DefinitelyUnassignedLateLocalVariableTest
    extends PubPackageResolutionTest {
  test_definitelyAssigned_after_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
  v += 1;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
  v;
}
''');
  }

  test_definitelyAssigned_after_postfixExpression_increment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
  v++;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
  v;
}
''');
  }

  test_mightBeAssigned_byPatternAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  late String s;
  () {
    (s,) = ('',);
  }();
  s;
}
''');
  }

  test_mightBeAssigned_if_else() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  late int v;
  if (c) {
    print(0);
  } else {
    v = 0;
  }
  v;
}
''');
  }

  test_mightBeAssigned_if_then() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  late int v;
  if (c) {
    v = 0;
  }
  v;
}
''');
  }

  test_mightBeAssigned_while() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  late int v;
  while (c) {
    v = 0;
  }
  v;
}
''');
  }

  test_neverAssigned_assignment_compound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v += 1;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
}
''');
  }

  test_neverAssigned_assignment_pure() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v = 0;
}
''');
  }

  test_neverAssigned_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int? v;
  v;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
}
''');
  }

  test_neverAssigned_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  ++v;
//  ^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
}
''');
  }

  test_neverAssigned_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
  v;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
}
''');
  }

  test_neverAssigned_suffixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int v;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v++;
//^
// [diag.definitelyUnassignedLateLocalVariable] The late local variable 'v' is definitely unassigned at this point.
}
''');
  }
}
