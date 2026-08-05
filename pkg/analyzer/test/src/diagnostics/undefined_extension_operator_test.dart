// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionOperatorTest extends PubPackageResolutionTest {
  test_binary_defined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {
  void operator +(int offset) {}
}
f() {
  E('a') + 1;
}
''');
  }

  test_binary_undefined() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on String {}
f() {
  E('a') + 1;
//       ^
// [diag.undefinedExtensionOperator] The operator '+' isn't defined for the extension 'E'.
}
''');

    var node = result.findNode.binary('+ 1');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleStringLiteral
          literal: 'a'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: String
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_index_get_hasGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0];
}
''');
  }

  test_index_get_hasNone() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0];
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]' isn't defined for the extension 'E'.
}
''');
  }

  test_index_get_hasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0];
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]' isn't defined for the extension 'E'.
}
''');
  }

  test_index_getSet_hasBoth() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] += 1;
}
''');
  }

  test_index_getSet_hasGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0] += 1;
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]=' isn't defined for the extension 'E'.
}
''');
  }

  test_index_getSet_hasNone() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0] += 1;
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]' isn't defined for the extension 'E'.
// [diag.undefinedExtensionOperator] The operator '[]=' isn't defined for the extension 'E'.
}
''');
  }

  test_index_getSet_hasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] += 1;
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]' isn't defined for the extension 'E'.
}
''');
  }

  test_index_set_hasGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  E(a)[0] = 1;
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]=' isn't defined for the extension 'E'.
}
''');
  }

  test_index_set_hasNone() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {}

f(A a) {
  E(a)[0] = 1;
//    ^^^
// [diag.undefinedExtensionOperator] The operator '[]=' isn't defined for the extension 'E'.
}
''');
  }

  test_index_set_hasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  E(a)[0] = 1;
}
''');
  }

  test_prefix_minus_defined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {
  String operator -() => substring(1);
}
f() {
  -E('a');
}
''');
  }

  test_prefix_minus_undefined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {}
f() {
  -E('a');
//^
// [diag.undefinedExtensionOperator] The operator 'unary-' isn't defined for the extension 'E'.
}
''');
  }
}
