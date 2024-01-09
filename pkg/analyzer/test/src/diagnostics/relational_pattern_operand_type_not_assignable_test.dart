// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternArgumentTypeNotAssignableTest);
  });
}

@reflectiveTest
class RelationalPatternArgumentTypeNotAssignableTest
    extends PubPackageResolutionTest {
  test_bangEq_matchedValueNullable() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
class A {
  bool operator ==(covariant A other) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE,
          101, 1),
    ]);
  }

  test_eqEq_externalType_right() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case == null:
      break;
  }
}
''');
  }

  test_eqEq_operandNullable() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
class A {
  bool operator >(A other) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE,
          89, 1),
    ]);
  }
}
