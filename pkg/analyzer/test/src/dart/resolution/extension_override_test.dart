// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionOverrideResolutionTest extends PubPackageResolutionTest {
  test_call_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int call(String s) => 0;
}
void f(A a) {
  E(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: <testLibrary>::@extension::E::@method::call
  staticInvokeType: int Function(String)
  staticType: int
''');
  }

  test_call_noPrefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
void f(A a) {
  E<String>(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('(a)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element2: dart:core::@class::String
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      String
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: MethodMember
    baseElement: <testLibrary>::@extension::E::@method::call
    substitution: {T: String}
  staticInvokeType: int Function(String)
  staticType: int
''');
  }

  test_call_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int call(String s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: package:test/lib.dart::@extension::E::@method::call
  staticInvokeType: int Function(String)
  staticType: int
''');
  }

  test_call_prefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<String>(a)('');
}
''');

    var node = findNode.functionExpressionInvocation('(a)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element2: dart:core::@class::String
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      String
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: MethodMember
    baseElement: package:test/lib.dart::@extension::E::@method::call
    substitution: {T: String}
  staticInvokeType: int Function(String)
  staticType: int
''');
  }

  test_getter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get g => 0;
}
void f(A a) {
  E(a).g;
}
''');

    var node = findNode.propertyAccess('E(a)');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    element: <testLibrary>::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
  }

  test_getter_noPrefix_noTypeArguments_functionExpressionInvocation() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  double Function(int) get g => (b) => 2.0;
}

void f(A a) {
  E(a).g(0);
}
''');

    var node = findNode.functionExpressionInvocation('E(a)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: g
      element: <testLibrary>::@extension::E::@getter::g
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_getter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get g => 0;
}
void f(A a) {
  E<int>(a).g;
}
''');

    var node = findNode.propertyAccess('(a)');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    element: <testLibrary>::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
  }

  test_getter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).g;
}
''');

    var node = findNode.propertyAccess('E(a)');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    element: package:test/lib.dart::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
  }

  test_getter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).g;
}
''');

    var node = findNode.propertyAccess('(a)');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    element: package:test/lib.dart::@extension::E::@getter::g
    staticType: int
  staticType: int
''');
  }

  test_indexExpression_read_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int operator [](int index) => 0;
}

void f(int? a) {
  E(a)?[0];
}
''');

    assertResolvedNodeText(findNode.index('[0]'), r'''
IndexExpression
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int?
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@extension::E::@method::[]
  staticType: int?
''');
  }

  test_indexExpression_write_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  operator []=(int index, int value) {}
}

void f(int? a) {
  E(a)?[0] = 1;
}
''');

    assertResolvedNodeText(findNode.assignment('[0] ='), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: int?
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: int
      staticType: null
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@method::[]=
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_method_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');

    var node = findNode.methodInvocation('E(a)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_method_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void m() {}
}
void f(A a) {
  E<int>(a).m();
}
''');

    var node = findNode.methodInvocation('(a)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_method_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).m();
}
''');

    var node = findNode.methodInvocation('E(a)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: package:test/lib.dart::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_method_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).m();
}
''');

    var node = findNode.methodInvocation('(a)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: package:test/lib.dart::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int foo() => 0;
}

void f(int? a) {
  E(a)?.foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int?
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_operator_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void operator +(int offset) {}
}
void f(A a) {
  E(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::offset
    staticType: int
  element: <testLibrary>::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_operator_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
void f(A a) {
  E<int>(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::offset
    staticType: int
  element: <testLibrary>::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_operator_onTearOff() async {
    // https://github.com/dart-lang/sdk/issues/38653
    await assertErrorsInCode(
      '''
extension E on int {
  v() {}
}

f(){
  E(0).v++;
}
''',
      [error(CompileTimeErrorCode.undefinedExtensionSetter, 45, 1)],
    );

    var node = findNode.postfix('++;');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: int
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@extension::E::@method::v
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_operator_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/lib.dart::@extension::E::@method::+::@formalParameter::offset
    staticType: int
  element: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_operator_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a) + 1;
}
''');

    var node = findNode.binary('(a)');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: package:test/lib.dart::@extension::E
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/lib.dart::@extension::E::@method::+::@formalParameter::offset
    staticType: int
  element: package:test/lib.dart::@extension::E::@method::+
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_promotion() async {
    await assertNoErrorsInCode(r'''
class C {
  int f() => 0;
}

extension E on C {
  int g(dynamic d) => 0;
}

void test(C? c) {
  E(c)?.g(c); // `c` is promoted to `C` on the RHS of `?.`
}
''');
    var node = findNode.simple('c);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: c
  correspondingParameter: <testLibrary>::@extension::E::@method::g::@formalParameter::d
  element: <testLibrary>::@function::test::@formalParameter::c
  staticType: C
''');
  }

  test_propertyAccess_getter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

void f(int? a) {
  E(a)?.foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int?
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int?
''');
  }

  test_propertyAccess_setter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

void f(int? a) {
  E(a)?.foo = 0;
}
''');
  }

  test_setter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  set s(int x) {}
}
void f(A a) {
  E(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::x
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::s
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_setter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::x
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::s
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_setter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: package:test/lib.dart::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/lib.dart::@extension::E::@setter::s::@formalParameter::x
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_setter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s = 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: package:test/lib.dart::@extension::E
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/lib.dart::@extension::E::@setter::s::@formalParameter::x
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_setterAndGetter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::s
  readType: int
  writeElement2: <testLibrary>::@extension::E::@setter::s
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_setterAndGetter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::s
  readType: int
  writeElement2: <testLibrary>::@extension::E::@setter::s
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_setterAndGetter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: package:test/lib.dart::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: package:test/lib.dart::@extension::E::@getter::s
  readType: int
  writeElement2: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_setterAndGetter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s += 0;
}
''');

    var node = findNode.assignment('(a)');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: package:test/lib.dart::@extension::E
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: package:test/lib.dart::@extension::E::@getter::s
  readType: int
  writeElement2: package:test/lib.dart::@extension::E::@setter::s
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => E(c).a;
''');

    var node = findNode.propertyAccess('E(c)');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::c
          staticType: C
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: C
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <testLibrary>::@extension::E::@method::a
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }
}
