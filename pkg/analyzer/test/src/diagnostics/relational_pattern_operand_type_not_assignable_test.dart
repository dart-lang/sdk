// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternArgumentTypeNotAssignableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RelationalPatternArgumentTypeNotAssignableTest
    extends PubPackageResolutionTest {
  test_bangEq_matchedValueNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A? x) {
  switch (x) {
    case != null:
      break;
  }
}
''');
  }

  test_bangEq_operandNull() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A x) {
  switch (x) {
    case != null:
      break;
  }
}
''');
  }

  test_bangEq_operandNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

const int? y = 0;

void f(A x) {
  switch (x) {
    case != y:
      break;
  }
}
''');
  }

  test_eqEq() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
  }

  test_eqEq_covariantParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator ==(covariant A other) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
//          ^
// [diag.relationalPatternOperandTypeNotAssignable] The constant expression type 'int' is not assignable to the parameter type 'A' of the '==' operator.
      break;
  }
}
''');
  }

  test_eqEq_externalType_right() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const A(bool it) {}
const True = A(true);

void f(bool x) {
  switch (x) {
    case == True:
    default:
  }
}
''');
  }

  test_eqEq_matchedValueNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A? x) {
  switch (x) {
    case == null:
      break;
  }
}
''');
  }

  test_eqEq_operandNull() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A x) {
  switch (x) {
    case == null:
      break;
//    ^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_eqEq_operandNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

const int? y = 0;

void f(A x) {
  switch (x) {
    case == y:
      break;
  }
}
''');
  }

  test_greaterThan() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator >(A other) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
//         ^
// [diag.relationalPatternOperandTypeNotAssignable] The constant expression type 'int' is not assignable to the parameter type 'A' of the '>' operator.
      break;
  }
}
''');
  }
}
