// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest);
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest_Language219);
  });
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest extends PubPackageResolutionTest
    with CaseExpressionTypeImplementsEqualsTestCases {
  @override
  _Variants get _variant => _Variants.patterns;
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest_Language219
    extends PubPackageResolutionTest
    with WithLanguage219Mixin, CaseExpressionTypeImplementsEqualsTestCases {
  @override
  _Variants get _variant => _Variants.nullSafe;
}

mixin CaseExpressionTypeImplementsEqualsTestCases on PubPackageResolutionTest {
  _Variants get _variant;

  test_classInstance_declares() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;

  const A(this.value);

  bool operator==(Object other);
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
    case const A(1):
      break;
  }
}
''');
  }

  test_classInstance_fromObject() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;
  const A(this.value);
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
  }
}
''');
  }

  test_classInstance_implements() async {
    if (_variant == _Variants.nullSafe) {
      await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;

  const A(this.value);

  bool operator ==(Object other) {
    return false;
  }
}

void f(e) {
  switch (e) {
    case const A(0):
//       ^^^^^^^^^^
// [diag.caseExpressionTypeImplementsEquals] The switch case expression type 'A' can't override the '==' operator.
      break;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;

  const A(this.value);

  bool operator ==(Object other) {
    return false;
  }
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
  }
}
''');
    }
  }

  test_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(e) {
  switch (e) {
    case 0:
      break;
  }
}
''');
  }

  test_String() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(e) {
  switch (e) {
    case '0':
      break;
  }
}
''');
  }
}

enum _Variants { nullSafe, patterns }
