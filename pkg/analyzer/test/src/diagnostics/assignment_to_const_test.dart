// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToConstTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToConstTest extends PubPackageResolutionTest {
  test_instanceVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const v = 0;
}
f() {
  A.v = 1;
//  ^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}''');
  }

  test_instanceVariable_plusEq() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const v = 0;
}
f() {
  A.v += 1;
//  ^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}''');
  }

  test_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = 1;
//^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}''');
  }

  test_localVariable_inForEach() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
  for (x in <int>[1, 2]) {
//     ^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
    print(x);
  }
}''');
  }

  test_localVariable_plusEq() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x += 1;
//^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}''');
  }
}
