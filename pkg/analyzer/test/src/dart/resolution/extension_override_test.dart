// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideResolutionTest);
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::E::@method::call
  element: <testLibraryFragment>::@extension::E::@method::call#element
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
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
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
  staticElement: MethodMember
    base: <testLibraryFragment>::@extension::E::@method::call
    substitution: {T: String}
  element: <testLibraryFragment>::@extension::E::@method::call#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@method::call
  element: package:test/lib.dart::<fragment>::@extension::E::@method::call#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
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
  staticElement: MethodMember
    base: package:test/lib.dart::<fragment>::@extension::E::@method::call
    substitution: {T: String}
  element: package:test/lib.dart::<fragment>::@extension::E::@method::call#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: <testLibraryFragment>::@extension::E::@getter::g
    element: <testLibraryFragment>::@extension::E::@getter::g#element
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: g
      staticElement: <testLibraryFragment>::@extension::E::@getter::g
      element: <testLibraryFragment>::@extension::E::@getter::g#element
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: GetterMember
      base: <testLibraryFragment>::@extension::E::@getter::g
      substitution: {T: int}
    element: <testLibraryFragment>::@extension::E::@getter::g#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::g
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::g#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: g
    staticElement: GetterMember
      base: package:test/lib.dart::<fragment>::@extension::E::@getter::g
      substitution: {T: int}
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::g#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: int?
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: int
    staticType: null
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: int?
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: int
      staticType: null
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@method::[]=
  writeElement2: <testLibraryFragment>::@extension::E::@method::[]=#element
  writeType: int
  staticElement: <null>
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: <testLibraryFragment>::@extension::E::@method::m
    element: <testLibraryFragment>::@extension::E::@method::m#element
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::E::@method::m
      substitution: {T: int}
    element: <testLibraryFragment>::@extension::E::@method::m#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@method::m
    element: package:test/lib.dart::<fragment>::@extension::E::@method::m#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    staticElement: MethodMember
      base: package:test/lib.dart::<fragment>::@extension::E::@method::m
      substitution: {T: int}
    element: package:test/lib.dart::<fragment>::@extension::E::@method::m#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: int?
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: int
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_operator_onTearOff() async {
    // https://github.com/dart-lang/sdk/issues/38653
    await assertErrorsInCode('''
extension E on int {
  v() {}
}

f(){
  E(0).v++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 45, 1),
    ]);

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
            parameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: int
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@extension::E::@method::v
  readElement2: <testLibraryFragment>::@extension::E::@method::v#element
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::<fragment>::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@method::+
  element: package:test/lib.dart::<fragment>::@extension::E::@method::+#element
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
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: package:test/lib.dart::<fragment>::@extension::E
    element2: package:test/lib.dart::<fragment>::@extension::E#element
    extendedType: A
    staticType: null
    typeArgumentTypes
      int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: package:test/lib.dart::<fragment>::@extension::E::@method::+::@parameter::offset
    staticType: int
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@method::+
  element: package:test/lib.dart::<fragment>::@extension::E::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: int?
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: int
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extension::E::@setter::s::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::s
  writeElement2: <testLibraryFragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: <null>
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
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: <testLibraryFragment>::@extension::E::@setter::s::@parameter::x
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: SetterMember
    base: <testLibraryFragment>::@extension::E::@setter::s
    substitution: {T: int}
  writeElement2: <testLibraryFragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: <null>
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
        element: <testLibraryFragment>::@prefix::p
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: package:test/lib.dart::<fragment>::@extension::E
      element2: package:test/lib.dart::<fragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: package:test/lib.dart::<fragment>::@extension::E::@setter::s::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: package:test/lib.dart::<fragment>::@extension::E::@setter::s
  writeElement2: package:test/lib.dart::<fragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: <null>
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
        element: <testLibraryFragment>::@prefix::p
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: package:test/lib.dart::<fragment>::@extension::E
      element2: package:test/lib.dart::<fragment>::@extension::E#element
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/lib.dart::<fragment>::@extension::E::@setter::s::@parameter::x
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: SetterMember
    base: package:test/lib.dart::<fragment>::@extension::E::@setter::s
    substitution: {T: int}
  writeElement2: package:test/lib.dart::<fragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: <null>
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::s
  readElement2: <testLibraryFragment>::@extension::E::@getter::s#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@setter::s
  writeElement2: <testLibraryFragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: GetterMember
    base: <testLibraryFragment>::@extension::E::@getter::s
    substitution: {T: int}
  readElement2: <testLibraryFragment>::@extension::E::@getter::s#element
  readType: int
  writeElement: SetterMember
    base: <testLibraryFragment>::@extension::E::@setter::s
    substitution: {T: int}
  writeElement2: <testLibraryFragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
        element: <testLibraryFragment>::@prefix::p
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: package:test/lib.dart::<fragment>::@extension::E
      element2: package:test/lib.dart::<fragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: package:test/lib.dart::<fragment>::@extension::E::@getter::s
  readElement2: package:test/lib.dart::<fragment>::@extension::E::@getter::s#element
  readType: int
  writeElement: package:test/lib.dart::<fragment>::@extension::E::@setter::s
  writeElement2: package:test/lib.dart::<fragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
        element: <testLibraryFragment>::@prefix::p
        element2: <testLibraryFragment>::@prefix2::p
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: package:test/lib.dart::<fragment>::@extension::E
      element2: package:test/lib.dart::<fragment>::@extension::E#element
      extendedType: A
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: s
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: GetterMember
    base: package:test/lib.dart::<fragment>::@extension::E::@getter::s
    substitution: {T: int}
  readElement2: package:test/lib.dart::<fragment>::@extension::E::@getter::s#element
  readType: int
  writeElement: SetterMember
    base: package:test/lib.dart::<fragment>::@extension::E::@setter::s
    substitution: {T: int}
  writeElement2: package:test/lib.dart::<fragment>::@extension::E::@setter::s#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::c
          element: <testLibraryFragment>::@function::f::@parameter::c#element
          staticType: C
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: C
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }
}
