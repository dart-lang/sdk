// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      RelationalPatternOperatorReturnTypeNotAssignableToBoolTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RelationalPatternOperatorReturnTypeNotAssignableToBoolTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
}
''');
  }

  test_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
//           ^
// [diag.relationalPatternOperatorReturnTypeNotAssignableToBool] The return type of operators used in relational patterns must be assignable to 'bool'.
}
''');
  }

  test_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Object operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
//           ^
// [diag.relationalPatternOperatorReturnTypeNotAssignableToBool] The return type of operators used in relational patterns must be assignable to 'bool'.
}
''');
  }
}
