// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    if (_variant == _Variant.nullSafe) {
      await resolveTestCodeWithDiagnostics('''
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
//       ^^
// [diag.caseExpressionTypeIsNotSwitchExpressionSubtype] The switch case expression type 'dynamic' must be a subtype of the switch expression type 'A'.
// [diag.caseExpressionTypeImplementsEquals] The switch case expression type 'B' can't override the '==' operator.
      break;
    case const B(1):
//       ^^^^^^^^^^
// [diag.caseExpressionTypeIsNotSwitchExpressionSubtype] The switch case expression type 'B' must be a subtype of the switch expression type 'A'.
// [diag.caseExpressionTypeImplementsEquals] The switch case expression type 'B' can't override the '==' operator.
      break;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics('''
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
''');
    }
  }

  test_notSubtype_primitiveEquality() async {
    if (_variant == _Variant.nullSafe) {
      await resolveTestCodeWithDiagnostics('''
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
//       ^^
// [diag.caseExpressionTypeIsNotSwitchExpressionSubtype] The switch case expression type 'dynamic' must be a subtype of the switch expression type 'A'.
      break;
    case const B(1):
//       ^^^^^^^^^^
// [diag.caseExpressionTypeIsNotSwitchExpressionSubtype] The switch case expression type 'B' must be a subtype of the switch expression type 'A'.
      break;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics('''
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
//       ^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'A' can never be equal to this constant of type 'B'.
      break;
    case const B(1):
//       ^^^^^^^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'A' can never be equal to this constant of type 'B'.
      break;
  }
}
''');
    }
  }

  test_subtype() async {
    await resolveTestCodeWithDiagnostics('''
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
