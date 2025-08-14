// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeIsNotSwitchExpressionSubtypeTest);
    defineReflectiveTests(
      CaseExpressionTypeIsNotSwitchExpressionSubtypeTest_Language219,
    );
  });
}

@reflectiveTest
class CaseExpressionTypeIsNotSwitchExpressionSubtypeTest
    extends PubPackageResolutionTest
    with CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases {
  @override
  _Variant get _variant => _Variant.patterns;
}

@reflectiveTest
class CaseExpressionTypeIsNotSwitchExpressionSubtypeTest_Language219
    extends PubPackageResolutionTest
    with
        WithLanguage219Mixin,
        CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases {
  @override
  _Variant get _variant => _Variant.nullSafe;
}

mixin CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases
    on PubPackageResolutionTest {
  _Variant get _variant;

  test_notSubtype_hasEqEq() async {
    List<ExpectedError> expectedErrors;
    switch (_variant) {
      case _Variant.nullSafe:
        expectedErrors = [
          error(
            CompileTimeErrorCode.caseExpressionTypeIsNotSwitchExpressionSubtype,
            180,
            2,
          ),
          error(
            CompileTimeErrorCode.caseExpressionTypeImplementsEquals,
            180,
            2,
          ),
          error(
            CompileTimeErrorCode.caseExpressionTypeIsNotSwitchExpressionSubtype,
            206,
            10,
          ),
          error(
            CompileTimeErrorCode.caseExpressionTypeImplementsEquals,
            206,
            10,
          ),
        ];
      case _Variant.patterns:
        expectedErrors = [];
    }

    await assertErrorsInCode('''
class A {
  const A();
}

class B {
  final int value;
  const B(this.value);
  bool operator ==(other) => true;
}

const dynamic B0 = B(0);

void f(A e) {
  switch (e) {
    case B0:
      break;
    case const B(1):
      break;
  }
}
''', expectedErrors);
  }

  test_notSubtype_primitiveEquality() async {
    List<ExpectedError> expectedErrors;
    switch (_variant) {
      case _Variant.nullSafe:
        expectedErrors = [
          error(
            CompileTimeErrorCode.caseExpressionTypeIsNotSwitchExpressionSubtype,
            145,
            2,
          ),
          error(
            CompileTimeErrorCode.caseExpressionTypeIsNotSwitchExpressionSubtype,
            171,
            10,
          ),
        ];
      case _Variant.patterns:
        expectedErrors = [
          error(WarningCode.constantPatternNeverMatchesValueType, 145, 2),
          error(WarningCode.constantPatternNeverMatchesValueType, 171, 10),
        ];
    }

    await assertErrorsInCode('''
class A {
  const A();
}

class B {
  final int value;
  const B(this.value);
}

const dynamic B0 = B(0);

void f(A e) {
  switch (e) {
    case B0:
      break;
    case const B(1):
      break;
  }
}
''', expectedErrors);
  }

  test_subtype() async {
    await assertNoErrorsInCode('''
class A {
  final int value;
  const A(this.value);
}

class B extends A {
  const B(int value) : super(value);
}

class C extends A {
  const C(int value) : super(value);
}

void f(A e) {
  switch (e) {
    case const B(0):
      break;
    case const C(0):
      break;
  }
}
''');
  }
}

enum _Variant { nullSafe, patterns }
