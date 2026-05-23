// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeLiteralResolutionTest);
    defineReflectiveTests(TypeLiteralResolutionTest_WithoutConstructorTearoffs);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeLiteralResolutionTest extends PubPackageResolutionTest {
  test_class_argumentList_argument_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f(Type t) {}
void g() {
  f(C<int>);
}
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_class_argumentList_argument_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f(Type t) {}
void g() {
  f(C);
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_class_argumentList_argument_parenthesizedExpression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f(Type t) {}
void g() {
  f((C<int>));
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_argumentList_argument_parenthesizedExpression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Type t) {}
void g() {
  f((a.C<int>));
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_argumentList_argument_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Type t) {}
void g() {
  f(a.C<int>);
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_class_argumentList_argument_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Type t) {}
void g() {
  f(a.C);
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_class_asExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Object f() {
  return C as Object;
}
''');

    var node = result.findNode.typeLiteral('C as');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_asExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Object f() {
  return a.C as Object;
}
''');

    var node = result.findNode.typeLiteral('a.C as');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertInitializer_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
class A {
  A() : assert(C);
//             ^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertInitializer_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
class A {
  A() : assert(a.C);
//             ^^^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertInitializer_message_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
class A {
  A() : assert(true, C);
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertInitializer_message_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
class A {
  A() : assert(true, a.C);
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertStatement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  assert(C);
//       ^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertStatement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  assert(a.C);
//       ^^^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertStatement_message_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  assert(true, C);
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assertStatement_message_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  assert(true, a.C);
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_assignmentExpression_rightHandSide_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type t = int;
void f() {
  t = C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  correspondingParameter: <testLibrary>::@setter::t::@formalParameter::value
  staticType: Type
''');
  }

  test_class_assignmentExpression_rightHandSide_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type t = int;
void f() {
  t = C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  correspondingParameter: <testLibrary>::@setter::t::@formalParameter::value
  staticType: Type
''');
  }

  test_class_assignmentExpression_rightHandSide_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type t = int;
void f() {
  t = a.C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  correspondingParameter: <testLibrary>::@setter::t::@formalParameter::value
  staticType: Type
''');
  }

  test_class_assignmentExpression_rightHandSide_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type t = int;
void f() {
  t = a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  correspondingParameter: <testLibrary>::@setter::t::@formalParameter::value
  staticType: Type
''');
  }

  test_class_awaitExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Future<Type> f() async {
  return await C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_awaitExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Future<Type> f() async {
  return await a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_binaryExpression_leftOperand_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  C<int> == int;
}
''');

    var node = result.findNode.typeLiteral('C<int> ==');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_binaryExpression_leftOperand_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  C == int;
}
''');

    var node = result.findNode.typeLiteral('C ==');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_binaryExpression_leftOperand_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C<int> == int;
}
''');

    var node = result.findNode.typeLiteral('C<int> ==');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_binaryExpression_leftOperand_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C == int;
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_ifNull_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Type? x;
void f() {
  x ?? C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_ifNull_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type? x;
void f() {
  x ?? a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  int == C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  int == C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  int == a.C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_class_binaryExpression_rightOperand_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  int == a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_methodInvocation_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  C..toString();
}
''');

    var node = result.findNode.typeLiteral('C..');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_methodInvocation_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C..toString();
}
''');

    var node = result.findNode.typeLiteral('a.C..');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  C..hashCode;
}
''');

    var node = result.findNode.typeLiteral('C..');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_parenthesized_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  (C<int>)..hashCode;
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_parenthesized_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  (a.C<int>)..hashCode;
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_cascadeExpression_target_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C..hashCode;
}
''');

    var node = result.findNode.typeLiteral('a.C..');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_conditionalExpression_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
var x = C ? 0 : 1;
//      ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('C ?');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_conditionalExpression_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var x = a.C ? 0 : 1;
//      ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('a.C ?');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_conditionalExpression_elseExpression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
bool b = true;
var y = b ? int : C<int>;
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_conditionalExpression_elseExpression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bool b = true;
var y = b ? int : a.C<int>;
''');

    var node = result.findNode.typeLiteral('a.C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_conditionalExpression_thenExpression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
bool b = true;
var y = b ? C<int> : int;
''');

    var node = result.findNode.typeLiteral('C<int> :');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_conditionalExpression_thenExpression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bool b = true;
var y = b ? a.C<int> : int;
''');

    var node = result.findNode.typeLiteral('a.C<int> :');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_constructorFieldInitializer_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
class A {
  Object o;
  A() : o = C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_constructorFieldInitializer_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
class A {
  Object o;
  A() : o = a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_defaultValue_optionalPositional_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f([Object o = C]) {}
''');

    var node = result.findNode.typeLiteral('C])');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_defaultValue_optionalPositional_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f([Object o = a.C]) {}
''');

    var node = result.findNode.typeLiteral('a.C])');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_doStatement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  do {} while (C);
//             ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_doStatement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  do {} while (a.C);
//             ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_expressionFunctionBody_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type f() => C<int>;
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_expressionFunctionBody_expression_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type f() => C;
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_expressionFunctionBody_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type f() => a.C<int>;
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_expressionFunctionBody_expression_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type f() => a.C;
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_expressionStatement_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_expressionStatement_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_expressionStatement_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void f() {
  a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_expressionStatement_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C<int>;
}
''');

    var node = result.findNode.typeLiteral('a.C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_forEachParts_iterable_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  for (var e in C) {
//              ^
// [diag.forInOfInvalidType] The type 'Type' used in the 'for' loop must implement 'Iterable'.
    e;
  }
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forEachParts_iterable_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  for (var e in a.C) {
//              ^^^
// [diag.forInOfInvalidType] The type 'Type' used in the 'for' loop must implement 'Iterable'.
    e;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forElement_forEachParts_iterable_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
var v = [for (var e in C) e];
//                     ^
// [diag.forInOfInvalidType] The type 'Type' used in the 'for' loop must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('C) e');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forElement_forEachParts_iterable_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var v = [for (var e in a.C) e];
//                     ^^^
// [diag.forInOfInvalidType] The type 'Type' used in the 'for' loop must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('a.C) e');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forParts_initialization_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(bool b) {
  for (C; b; ) {
    break;
  }
}
''');

    var node = result.findNode.typeLiteral('C; b');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forParts_initialization_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(bool b) {
  for (a.C; b; ) {
    break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C; b');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forParts_updaters_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(bool b) {
  for (; b; C) {}
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forParts_updaters_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(bool b) {
  for (; b; a.C) {}
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forStatement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  for (; C; ) {}
//       ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C; )');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_forStatement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  for (; a.C; ) {}
//       ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C; )');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_guardedPattern_whenClause_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case _ when C:
//              ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_guardedPattern_whenClause_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case _ when a.C:
//              ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<int> f(Object x) {
  return [if (x case C) 0];
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<int> f(Object x) {
  return [if (x case a.C) 0];
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_mapPatternEntry_key_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<int> f(Object x) {
  return [if (x case {C: 0}) 0];
}
''');

    var node = result.findNode.typeLiteral('C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_mapPatternEntry_key_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<int> f(Object x) {
  return [if (x case {a.C: 0}) 0];
}
''');

    var node = result.findNode.typeLiteral('a.C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<int> f(Object x) {
  return [if (x case == C) 0];
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseElement_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<int> f(Object x) {
  return [if (x case == a.C) 0];
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  if (x case C) {}
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  if (x case a.C) {}
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_logicalOrPattern_leftOperand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  if (x case C || int) {}
}
''');

    var node = result.findNode.typeLiteral('C || int');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_logicalOrPattern_leftOperand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  if (x case a.C || int) {}
}
''');

    var node = result.findNode.typeLiteral('a.C || int');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_logicalOrPattern_rightOperand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  if (x case int || C) {}
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_logicalOrPattern_rightOperand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  if (x case int || a.C) {}
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_mapPatternEntry_key_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  if (x case {C: 0}) {}
}
''');

    var node = result.findNode.typeLiteral('C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_mapPatternEntry_key_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  if (x case {a.C: 0}) {}
}
''');

    var node = result.findNode.typeLiteral('a.C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  if (x case == C) {}
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifCaseStatement_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  if (x case == a.C) {}
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifElement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
var v = [if (C) 1];
//           ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('C) 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifElement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var v = [if (a.C) 1];
//           ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('a.C) 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifStatement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  if (C) {}
//    ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_ifStatement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  if (a.C) {}
//    ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_indexExpression_index_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(dynamic d) {
  d[C];
}
''');

    var node = result.findNode.typeLiteral('C];');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_class_indexExpression_index_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(dynamic d) {
  d[a.C];
}
''');

    var node = result.findNode.typeLiteral('a.C];');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_class_indexExpression_target_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(int i) {
  C[i];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'Type'.
}
''');

    var node = result.findNode.typeLiteral('C[i]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_indexExpression_target_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(int i) {
  a.C[i];
//   ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'Type'.
}
''');

    var node = result.findNode.typeLiteral('a.C[i]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_interpolationExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
var s = '${C}';
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_interpolationExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;
var s = '${a.C}';
''');

    var node = result.findNode.typeLiteral('a.C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_isExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
bool f() {
  return C is Type;
//       ^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');

    var node = result.findNode.typeLiteral('C is');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_isExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bool f() {
  return a.C is Type;
//       ^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');

    var node = result.findNode.typeLiteral('a.C is');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_elements_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var l = [C<int>];
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listLiteral_elements_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var l = [C];
''');

    var node = result.findNode.typeLiteral('C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_listLiteral_elements_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var l = [a.C<int>];
''');

    var node = result.findNode.typeLiteral('C<int>]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listLiteral_elements_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var l = [a.C];
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_listLiteral_forElement_body_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<Object> f() {
  return [for (var _ in [0]) C];
}
''');

    var node = result.findNode.typeLiteral('C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_forElement_body_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<Object> f() {
  return [for (var _ in [0]) a.C];
}
''');

    var node = result.findNode.typeLiteral('a.C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_ifElement_else_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<Object> f(bool b) {
  return [if (b) int else C];
}
''');

    var node = result.findNode.typeLiteral('C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_ifElement_else_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<Object> f(bool b) {
  return [if (b) int else a.C];
}
''');

    var node = result.findNode.typeLiteral('a.C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_ifElement_then_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
List<Object> f(bool b) {
  return [if (b) C];
}
''');

    var node = result.findNode.typeLiteral('C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_ifElement_then_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
List<Object> f(bool b) {
  return [if (b) a.C];
}
''');

    var node = result.findNode.typeLiteral('a.C]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listLiteral_spreadElement_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var l = [...C<int>];
//          ^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('C<int>]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listLiteral_spreadElement_expression_nullAware_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var l = [...?C<int>];
//       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//           ^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('C<int>]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listLiteral_spreadElement_expression_nullAware_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var l = [...?a.C<int>];
//       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//           ^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('a.C<int>]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listLiteral_spreadElement_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var l = [...a.C<int>];
//          ^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('a.C<int>]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_listPattern_element_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case [C]:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C]:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listPattern_element_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case [a.C]:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C]:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listPattern_element_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case [== C]:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C]:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_listPattern_element_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case [== a.C]:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C]:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapLiteral_ifElement_key_else_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Map<Object, int> f(bool b) {
  return {if (b) C: 1 else int: 2};
}
''');

    var node = result.findNode.typeLiteral('C: 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapLiteral_ifElement_key_else_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Map<Object, int> f(bool b) {
  return {if (b) a.C: 1 else int: 2};
}
''');

    var node = result.findNode.typeLiteral('a.C: 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapLiteral_ifElement_value_else_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Map<int, Object> f(bool b) {
  return {if (b) 1: C else 2: int};
}
''');

    var node = result.findNode.typeLiteral('C else');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapLiteral_ifElement_value_else_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Map<int, Object> f(bool b) {
  return {if (b) 1: a.C else 2: int};
}
''');

    var node = result.findNode.typeLiteral('a.C else');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapLiteral_key_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var m = {C<int>: 1};
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_key_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var m = {C: 1};
''');

    var node = result.findNode.typeLiteral('C: 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_mapLiteral_key_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var m = {a.C<int>: 1};
''');

    var node = result.findNode.typeLiteral('C<int>: 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_key_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var m = {a.C: 1};
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_mapLiteral_spreadElement_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Map<Object, Object> m = {...C<int>};
//                          ^^^^^^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_spreadElement_expression_nullAware_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Map<Object, Object> m = {...?C<int>};
//                       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                           ^^^^^^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_spreadElement_expression_nullAware_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Map<Object, Object> m = {...?a.C<int>};
//                       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                           ^^^^^^^^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');

    var node = result.findNode.typeLiteral('a.C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_spreadElement_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Map<Object, Object> m = {...a.C<int>};
//                          ^^^^^^^^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');

    var node = result.findNode.typeLiteral('a.C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_value_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var m = {1: C<int>};
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_value_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var m = {1: C};
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_mapLiteral_value_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var m = {1: a.C<int>};
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_mapLiteral_value_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var m = {1: a.C};
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_mapPatternEntry_key_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case {C: 0}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapPatternEntry_key_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case {a.C: 0}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapPatternEntry_value_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case {'k': C}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C}:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapPatternEntry_value_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case {'k': a.C}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C}:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapPatternEntry_value_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case {'k': == C}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C}:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_mapPatternEntry_value_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case {'k': == a.C}:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C}:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_methodInvocation_target_parenthesizedExpression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}

void bar() {
  (C<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_methodInvocation_target_parenthesizedExpression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  (a.C<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_namedExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f({required Type t}) {}
void g() {
  f(t: C);
}
''');

    var node = result.findNode.typeLiteral('C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_namedExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f({required Type t}) {}
void g() {
  f(t: a.C);
}
''');

    var node = result.findNode.typeLiteral('a.C);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_objectPattern_patternField_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
class A {
  final Object f;
  const A(this.f);
}
void f(Object x) {
  switch (x) {
    case A(f: C):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_objectPattern_patternField_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
class A {
  final Object f;
  const A(this.f);
}
void f(Object x) {
  switch (x) {
    case A(f: a.C):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_objectPattern_patternField_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
class A {
  final Object f;
  const A(this.f);
}
void f(Object x) {
  switch (x) {
    case A(f: == C):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C):');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_objectPattern_patternField_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
class A {
  final Object f;
  const A(this.f);
}
void f(Object x) {
  switch (x) {
    case A(f: == a.C):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C):');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_parenthesizedExpression_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  (C<int>);
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_parenthesizedExpression_expression_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
void f() {
  (C);
}
''');

    var node = result.findNode.typeLiteral('C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_parenthesizedExpression_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  (a.C<int>);
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_parenthesizedExpression_expression_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  (a.C);
}
''');

    var node = result.findNode.typeLiteral('a.C)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  @FailingTest(reason: 'TODO: decide exact diagnostic for TypeLiteral++')
  test_class_postfixExpression_operand_increment_noPrefix() async {
    // TODO(scheglov): Decide the exact diagnostic for `TypeLiteral++`.
    // Speculation: it should be `assignmentToType`.
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  C++;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.typeLiteral('C++;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  @FailingTest(reason: 'TODO: decide exact diagnostic for prefix.TypeLiteral++')
  test_class_postfixExpression_operand_increment_withPrefix() async {
    // TODO(scheglov): Decide the exact diagnostic for `prefix.TypeLiteral++`.
    // Speculation: it should be `assignmentToType` on `C`.
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  a.C++;
//  ^
// [diag.undefinedPrefixedName] The name 'C' is being referenced through the prefix 'a', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.typeLiteral('a.C++;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_prefixExpression_operand_bang_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
var x = !C;
//       ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_prefixExpression_operand_bang_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var x = !a.C;
//       ^^^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  @FailingTest(reason: 'TODO: decide exact diagnostic for ++TypeLiteral')
  test_class_prefixExpression_operand_increment_noPrefix() async {
    // TODO(scheglov): Decide the exact diagnostic for `++TypeLiteral`.
    // Speculation: it should be `assignmentToType`.
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  ++C;
//  ^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  @FailingTest(reason: 'TODO: decide exact diagnostic for ++prefix.TypeLiteral')
  test_class_prefixExpression_operand_increment_withPrefix() async {
    // TODO(scheglov): Decide the exact diagnostic for `++prefix.TypeLiteral`.
    // Speculation: it should be `assignmentToType` on `C`.
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  ++a.C;
//    ^
// [diag.undefinedPrefixedName] The name 'C' is being referenced through the prefix 'a', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_prefixExpression_operand_minus_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
var x = -C;
//      ^
// [diag.undefinedOperator] The operator 'unary-' isn't defined for the type 'Type'.
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_prefixExpression_operand_minus_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var x = -a.C;
//      ^
// [diag.undefinedOperator] The operator 'unary-' isn't defined for the type 'Type'.
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_propertyAccess_target_parenthesizedExpression_noPrefix_instantiated_getter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}

void bar() {
  (C<int>).foo;
}

extension E on Type {
  int get foo => 0;
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_propertyAccess_target_parenthesizedExpression_noPrefix_instantiated_setter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}

void bar() {
  (C<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');

    var node = result.findNode.typeLiteral('C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_propertyAccess_target_parenthesizedExpression_withPrefix_instantiated_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  (a.C<int>).foo;
}

extension E on Type {
  int get foo => 0;
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_propertyAccess_target_parenthesizedExpression_withPrefix_instantiated_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  (a.C<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');

    var node = result.findNode.typeLiteral('a.C<int>)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_recordLiteral_fields_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
(Object,) f() {
  return (C,);
}
''');

    var node = result.findNode.typeLiteral('C,);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_recordLiteral_fields_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
(Object,) f() {
  return (a.C,);
}
''');

    var node = result.findNode.typeLiteral('a.C,);');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_recordPattern_patternField_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case (C,):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C,)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_recordPattern_patternField_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case (a.C,):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C,)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_recordPattern_patternField_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case (== C,):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C,):');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_recordPattern_patternField_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case (== a.C,):
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C,):');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_returnStatement_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type f() {
  return C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_returnStatement_expression_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Type f() {
  return C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_returnStatement_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type f() {
  return a.C<int>;
}
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_returnStatement_expression_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Type f() {
  return a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_setLiteral_elements_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var s = {C<int>};
''');

    var node = result.findNode.typeLiteral('C<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_setLiteral_elements_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var s = {C};
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_setLiteral_elements_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var s = {a.C<int>};
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_setLiteral_elements_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var s = {a.C};
''');

    var node = result.findNode.typeLiteral('a.C');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_setLiteral_forElement_body_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Set<Object> f() {
  return {for (var _ in [0]) C};
}
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_forElement_body_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Set<Object> f() {
  return {for (var _ in [0]) a.C};
}
''');

    var node = result.findNode.typeLiteral('a.C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_ifElement_else_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Set<Object> f(bool b) {
  return {if (b) int else C};
}
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_ifElement_else_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Set<Object> f(bool b) {
  return {if (b) int else a.C};
}
''');

    var node = result.findNode.typeLiteral('a.C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_ifElement_then_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Set<Object> f(bool b) {
  return {if (b) C};
}
''');

    var node = result.findNode.typeLiteral('C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_ifElement_then_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Set<Object> f(bool b) {
  return {if (b) a.C};
}
''');

    var node = result.findNode.typeLiteral('a.C}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_setLiteral_spreadElement_expression_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Set<Object> s = {...C<int>};
//                  ^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_setLiteral_spreadElement_expression_nullAware_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
Set<Object> s = {...?C<int>};
//               ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                   ^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_setLiteral_spreadElement_expression_nullAware_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Set<Object> s = {...?a.C<int>};
//               ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                   ^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('a.C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_setLiteral_spreadElement_expression_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Set<Object> s = {...a.C<int>};
//                  ^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('a.C<int>}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_switchExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
int f() {
  return switch (C<int>) {
    _ => 0,
  };
}
''');

    var node = result.findNode.typeLiteral('C<int>) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_switchExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
int f() {
  return switch (a.C<int>) {
    _ => 0,
  };
}
''');

    var node = result.findNode.typeLiteral('a.C<int>) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_switchExpressionCase_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
int f(Object x) {
  return switch (x) {
    C => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('C =>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchExpressionCase_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
int f(Object x) {
  return switch (x) {
    a.C => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('a.C =>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchExpressionCase_mapPatternEntry_key_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
int f(Object x) {
  return switch (x) {
    {C: 0} => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchExpressionCase_mapPatternEntry_key_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
int f(Object x) {
  return switch (x) {
    {a.C: 0} => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('a.C: 0}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchExpressionCase_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
int f(Object x) {
  return switch (x) {
    == C => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('C =>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchExpressionCase_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
int f(Object x) {
  return switch (x) {
    == a.C => 0,
    _ => 1,
  };
}
''');

    var node = result.findNode.typeLiteral('a.C =>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_constantPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case C:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_constantPattern_operand_noPrefix_matchedValueTypeType() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Type t) {
  switch (t) {
    case C:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_constantPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case a.C:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_constantPattern_operand_withPrefix_matchedValueTypeType() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Type t) {
  switch (t) {
    case a.C:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_relationalPattern_operand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f(Object x) {
  switch (x) {
    case == C:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchPatternCase_relationalPattern_operand_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Object x) {
  switch (x) {
    case == a.C:
      break;
  }
}
''');

    var node = result.findNode.typeLiteral('a.C:');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchStatement_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  switch (C) {
    default:
  }
}
''');

    var node = result.findNode.typeLiteral('C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_switchStatement_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  switch (a.C) {
    default:
  }
}
''');

    var node = result.findNode.typeLiteral('a.C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_throwExpression_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
Never f() => throw C;
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_throwExpression_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
Never f() => throw a.C;
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var t = C<int>;
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_noPrefix_instantiated_tooFewTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
var t = C<int>;
//       ^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 2 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<dynamic, dynamic>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_noPrefix_instantiated_tooManyTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var t = C<int, int>;
//       ^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 1 type parameters, but 2 type arguments were given.
''');

    var node = result.findNode.typeLiteral('C<int, int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_noPrefix_instantiated_typeArgumentsDoNotMatchBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T extends num> {}
var t = C<String>;
//      ^^^^^^^^^
// [context 1] The inverted type 'C<String>' is also not regular-bounded, so the type is not well-bounded.
//        ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
''');

    var node = result.findNode.typeLiteral('C<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<String>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
var t = C;
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.C<int>;
''');

    var node = result.findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
    type: C<int>
  staticType: Type
''');
  }

  test_class_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.C;
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_whileStatement_condition_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
void f() {
  while (C) {}
//       ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_whileStatement_condition_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f() {
  while (a.C) {}
//       ^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');

    var node = result.findNode.typeLiteral('a.C) {');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_yieldStatement_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class C {}
Stream<Type> f() async* {
  yield C;
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_yieldStatement_expression_star_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class C {}
Stream<Type> f() async* {
  yield* C;
//       ^
// [diag.yieldEachOfInvalidType] The type 'Type' implied by the 'yield*' expression must be assignable to 'Stream<Type>'.
}
''');

    var node = result.findNode.typeLiteral('C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_yieldStatement_expression_star_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';
import 'a.dart' as a;
Stream<Type> f() async* {
  yield* a.C;
//       ^^^
// [diag.yieldEachOfInvalidType] The type 'Type' implied by the 'yield*' expression must be assignable to 'Stream<Type>'.
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }

  test_class_yieldStatement_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';
import 'a.dart' as a;
Stream<Type> f() async* {
  yield a.C;
}
''');

    var node = result.findNode.typeLiteral('a.C;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: C
    element: package:test/a.dart::@class::C
    type: C<dynamic>
  staticType: Type
''');
  }

  // TODO(scheglov): Holistic coverage proposals:
  //
  // 1. Instantiated Type Literals for Mixins:
  //    - `mixin M<T> {} var t = M<int>;` (Should be Type literal M<int>)
  //
  // 2. Type Literals for Enums:
  //    - `enum E {a} var t = E;` (Valid Type literal)
  //    - Enums cannot be generic, so `E<int>` should be error (unless E is alias?).
  //
  // 3. Type Parameters as Type Literals:
  //    - `class C<T> { void m() { var t = T; } }` (Runtime check? Valid)
  //    - `class C<T> { const m() { var t = T; } }` (Error if constant expression? Spec says T is potentially constant)
  //
  // 4. Cascades on Instantiated Type Literals:
  //    - `C<int>..toString()` (Should resolve to Type's toString, evaluating C<int> first)
  //    - `C<int>..hashCode`
  //
  // 5. Static member access on Instantiated Type Literals (Negative):
  //    - `C<int>.staticMethod` (Error)
  //    - `C<int>.staticGetter` (Error)
  //    - `C<int>.staticSetter = 1` (Error)
  //
  // 6. Constructor ambiguity & Members:
  //    - `C<int>.toString()` (Error: treats as constructor 'toString')
  //    - `C<int>.new` (Valid constructor tear-off)
  //    - `C<int>.named` (Valid constructor tear-off)
  //
  // 7. Deferred imports:
  //    - `import ... deferred as d;`
  //    - `d.C<int>` (Valid? Runtime check)
  //    - `const d.C<int>` (Error)
  //
  // 8. Negative Tests (Invalid Instantiations):
  //    - `dynamic<int>` (Error)
  //    - `Function<int>` (Error)
  //    - `void<int>` (Error)
  //    - `Never<int>` (Error)
  //    - `int<String>` (Error: int is not generic)
  //
  // 9. Ambiguous parsing/resolution contexts:
  //    - `f(C<int>)` vs `f(C<int>())`
  //    - `var x = C<int> + 1;` (Error? Type doesn't define operator +)
  //    - `var x = C<int> == C<int>;` (Valid)
  //
  // 10. Extension methods on Type vs Constructor:
  //    - `extension E on Type { void foo() {} }`
  //    - `C<int>.foo()` (Error: looks for constructor foo)
  //    - `(C<int>).foo()` (Valid: calls extension on Type)
  //
  // 11. Metadata:
  //    - `@C<int>` (Invalid metadata syntax? Metadata must be constructor call or constant. Type literal is constant.)
  //    - `@C` is allowed (as constructor tear-off? No, as opaque constant invocation or similar?)
  //    - Verify usage of Type Literals in annotations if allowed.
  //
  // 12. Type Aliases (Advanced):
  //    - `typedef A<T> = C<T>;`
  //    - `var t = A<int>.new;` (Constructor tear-off via alias)
  //    - `var t = A<int>.staticMethod;` (Error)
  //
  // 13. Function Type Aliases:
  //    - `typedef F<T> = void Function(T);`
  //    - `F<int>.toString()` (Error?)
  //    - `F<int>.new` (Error: Function types don't have constructors)

  test_classAlias_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<int>;
''');

    var node = result.findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::CA
    type: C<int>
      alias: <testLibrary>::@typeAlias::CA
        typeArguments
          int
  staticType: Type
''');
  }

  test_classAlias_variableDeclaration_initializer_noPrefix_instantiated_differentTypeArgCount() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
typedef CA<T> = C<T, int>;
var t = CA<String>;
''');

    var node = result.findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: <testLibrary>::@typeAlias::CA
    type: C<String, int>
      alias: <testLibrary>::@typeAlias::CA
        typeArguments
          String
  staticType: Type
''');
  }

  test_classAlias_variableDeclaration_initializer_noPrefix_instantiated_functionTypeArg() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<void Function()>;
''');

    var node = result.findNode.typeLiteral('CA<void Function()>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: void
            element: <null>
            type: void
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          declaredFragment: GenericFunctionTypeElement
            parameters
            returnType: void
            type: void Function()
          type: void Function()
      rightBracket: >
    element: <testLibrary>::@typeAlias::CA
    type: C<void Function()>
      alias: <testLibrary>::@typeAlias::CA
        typeArguments
          void Function()
  staticType: Type
''');
  }

  test_classAlias_variableDeclaration_initializer_noPrefix_instantiated_typeArgumentsDoNotMatchBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef CA<T extends num> = C<T>;
var t = CA<String>;
//      ^^^^^^^^^^
// [context 1] The inverted type 'CA<String>' is also not regular-bounded, so the type is not well-bounded.
//         ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
''');

    var node = result.findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: <testLibrary>::@typeAlias::CA
    type: C<String>
      alias: <testLibrary>::@typeAlias::CA
        typeArguments
          String
  staticType: Type
''');
  }

  test_classAlias_variableDeclaration_initializer_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
typedef CA<T> = C<T>;
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.CA<int>;
''');

    var node = result.findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::CA
    type: C<int>
      alias: package:test/a.dart::@typeAlias::CA
        typeArguments
          int
  staticType: Type
''');
  }

  test_dynamic_argumentList_argument_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Type t) {}
void g() {
  f(dynamic);
}
''');

    var node = result.findNode.typeLiteral('dynamic)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_dynamic_argumentList_argument_noPrefix_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Type t) {}
void g() {
  f((dynamic));
}
''');

    var node = result.findNode.typeLiteral('dynamic)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_argumentList_argument_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f(core.Type t) {}
void g() {
  f(core.dynamic);
}
''');

    var node = result.findNode.typeLiteral('dynamic)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_dynamic_binaryExpression_rightOperand_ifNull_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
Object? x;
var y = x ?? dynamic;
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_dynamic_binaryExpression_rightOperand_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  int == dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_dynamic_binaryExpression_rightOperand_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f() {
  core.int == core.dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_dynamic_conditionalExpression_elseExpression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool b = true;
var y = b ? int : dynamic;
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_conditionalExpression_thenExpression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool b = true;
var y = b ? dynamic : int;
''');

    var node = result.findNode.typeLiteral('dynamic :');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_expressionStatement_expression_noPrefix_explicitCore() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';

void f() {
  dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_expressionStatement_expression_noPrefix_implicitCore() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_expressionStatement_expression_withPrefix_explicitCore() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f() {
  core.dynamic;
}
''');

    var node = result.findNode.typeLiteral('core.dynamic');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_listLiteral_elements_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
var l = [dynamic];
''');

    var node = result.findNode.typeLiteral('dynamic]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_listLiteral_elements_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var l = [core.dynamic];
''');

    var node = result.findNode.typeLiteral('dynamic]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_listLiteral_ifElement_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool b = true;
var l = [if (b) dynamic];
''');

    var node = result.findNode.typeLiteral('dynamic]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_listLiteral_nullAwareSpread_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
var l = [...?dynamic];
//       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//           ^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('dynamic]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_listLiteral_spread_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
var l = [...dynamic];
//          ^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('dynamic]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_returnStatement_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
Type f() {
  return dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_returnStatement_expression_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.Type f() {
  return core.dynamic;
}
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_variableDeclaration_initializer_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = dynamic;
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_dynamic_variableDeclaration_initializer_noPrefix_hasTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = dynamic<int>;
//      ^^^^^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
''');

    // TODO(scheglov): This should be `TypeLiteral`.
    var node = result.findNode.functionReference('dynamic<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: dynamic
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_dynamic_variableDeclaration_initializer_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var t = core.dynamic;
''');

    var node = result.findNode.typeLiteral('dynamic;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    element: dynamic
    type: dynamic
  staticType: Type
''');
  }

  test_enum_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { v }
var t = E;
''');

    var node = result.findNode.typeLiteral('E;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: E
    element: <testLibrary>::@enum::E
    type: E
  staticType: Type
''');
  }

  test_enum_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E { v }
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.E;
''');

    var node = result.findNode.typeLiteral('E;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: E
    element: package:test/a.dart::@enum::E
    type: E
  staticType: Type
''');
  }

  test_extensionType_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A<T>(T it) {}
var t = A<int>;
''');

    var node = result.findNode.typeLiteral('A<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@extensionType::A
    type: A<int>
  staticType: Type
''');
  }

  test_extensionType_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {}
var t = A;
''');

    var node = result.findNode.typeLiteral('A;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: A
    element: <testLibrary>::@extensionType::A
    type: A
  staticType: Type
''');
  }

  test_extensionType_variableDeclaration_initializer_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
extension type A<T>(T it) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.A<int>;
''');

    var node = result.findNode.typeLiteral('A<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@extensionType::A
    type: A<int>
  staticType: Type
''');
  }

  test_extensionType_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
extension type A(int it) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.A;
''');

    var node = result.findNode.typeLiteral('A;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: A
    element: package:test/a.dart::@extensionType::A
    type: A
  staticType: Type
''');
  }

  test_functionTypeAlias_expressionStatement_expression_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef void F();
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void f() {
  a.F;
}
''');

    var node = result.findNode.typeLiteral('a.F');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: F
    element: package:test/a.dart::@typeAlias::F
    type: void Function()
      alias: package:test/a.dart::@typeAlias::F
  staticType: Type
''');
  }

  test_mixin_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin M<T> {}
var t = M<int>;
''');

    var node = result.findNode.typeLiteral('M<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: M
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@mixin::M
    type: M<int>
  staticType: Type
''');
  }

  test_mixin_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin M<T> {}
var t = M;
''');

    var node = result.findNode.typeLiteral('M;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: M
    element: <testLibrary>::@mixin::M
    type: M<dynamic>
  staticType: Type
''');
  }

  test_mixin_variableDeclaration_initializer_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
mixin M<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.M<int>;
''');

    var node = result.findNode.typeLiteral('M<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: M
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@mixin::M
    type: M<int>
  staticType: Type
''');
  }

  test_mixin_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
mixin M<T> {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.M;
''');

    var node = result.findNode.typeLiteral('M;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: M
    element: package:test/a.dart::@mixin::M
    type: M<dynamic>
  staticType: Type
''');
  }

  test_never_argumentList_argument_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Type t) {}
void g() {
  f(Never);
}
''');

    var node = result.findNode.typeLiteral('Never)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_never_argumentList_argument_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f(core.Type t) {}
void g() {
  f(core.Never);
}
''');

    var node = result.findNode.typeLiteral('Never)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::t
  staticType: Type
''');
  }

  test_never_argumentList_argument_withPrefix_notInstantiated_hasTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f(core.Object? x) {}
void g() {
  f(core.Never<core.int>);
}
''');

    // TODO(scheglov): This should be `TypeLiteral`.
    var node = result.findNode.functionReference('Never<core.int>)');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: core
      element: <testLibraryFragment>::@prefix::core
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: Never
      element: Never
      staticType: InvalidType
    element: Never
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        importPrefix: ImportPrefixReference
          name: core
          period: .
          element: <testLibraryFragment>::@prefix::core
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  correspondingParameter: <testLibrary>::@function::f::@formalParameter::x
  staticType: InvalidType
''');
  }

  test_never_argumentList_argument_withPrefix_notInstantiated_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f(core.Type t) {}
void g() {
  f((core.Never));
}
''');

    var node = result.findNode.typeLiteral('Never)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_binaryExpression_rightOperand_ifNull_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.Object? x;
var y = x ?? core.Never;
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_never_binaryExpression_rightOperand_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  int == Never;
}
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_never_binaryExpression_rightOperand_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
void f() {
  core.int == core.Never;
}
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_never_conditionalExpression_elseExpression_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.bool b = true;
var y = b ? core.int : core.Never;
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_conditionalExpression_thenExpression_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.bool b = true;
var y = b ? core.Never : core.int;
''');

    var node = result.findNode.typeLiteral('Never :');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_expressionStatement_expression_noPrefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  Never;
}
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_listLiteral_elements_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
var l = [Never];
''');

    var node = result.findNode.typeLiteral('Never]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_listLiteral_elements_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var l = [core.Never];
''');

    var node = result.findNode.typeLiteral('Never]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_listLiteral_ifElement_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.bool b = true;
var l = [if (b) core.Never];
''');

    var node = result.findNode.typeLiteral('Never]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_listLiteral_nullAwareSpread_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var l = [...?core.Never];
//       ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//           ^^^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('Never]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_listLiteral_spread_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var l = [...core.Never];
//          ^^^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');

    var node = result.findNode.typeLiteral('Never]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_returnStatement_expression_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
Type f() {
  return Never;
}
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_returnStatement_expression_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.Type f() {
  return core.Never;
}
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_setLiteral_ifElement_else_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
core.Set<core.Object> f(core.bool b) {
  return {if (b) core.int else core.Never};
}
''');

    var node = result.findNode.typeLiteral('Never}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = Never;
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_never_variableDeclaration_initializer_noPrefix_notInstantiated_hasTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = Never<int>;
//      ^^^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
''');

    // TODO(scheglov): This should be `TypeLiteral`.
    var node = result.findNode.functionReference('Never<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: Never
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_never_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;
var t = core.Never;
''');

    var node = result.findNode.typeLiteral('Never;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_typeAlias_argumentList_argument_withPrefix_notInstantiated_parenthesized() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void f(Type t) {}
void g() {
  f((a.F));
}
''');

    var node = result.findNode.typeLiteral('F))');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: F
    element: package:test/a.dart::@typeAlias::F
    type: void Function()
      alias: package:test/a.dart::@typeAlias::F
  staticType: Type
''');
  }

  test_typeAlias_expressionStatement_expression_withPrefix_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = void Function();
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void f() {
  a.A;
}
''');

    var node = result.findNode.typeLiteral('a.A');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: A
    element: package:test/a.dart::@typeAlias::A
    type: void Function()
      alias: package:test/a.dart::@typeAlias::A
  staticType: Type
''');
  }

  test_typeAlias_expressionStatement_expression_withPrefix_interfaceType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = List<int>;
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void f() {
  a.A;
}
''');

    var node = result.findNode.typeLiteral('a.A');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: A
    element: package:test/a.dart::@typeAlias::A
    type: List<int>
      alias: package:test/a.dart::@typeAlias::A
  staticType: Type
''');
  }

  test_typeAlias_methodInvocation_target_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
//        ^^^
// [diag.undefinedMethodOnFunctionType] The method 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  void foo() {}
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_methodInvocation_target_noPrefix_instantiated_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_methodInvocation_target_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  a.Fn<int>.foo();
//          ^^^
// [diag.undefinedMethodOnFunctionType] The method 'foo' isn't defined for the 'a.Fn' function type.
}

extension E on Type {
  void foo() {}
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::Fn
    type: void Function(int)
      alias: package:test/a.dart::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_propertyAccess_target_noPrefix_instantiated_getter() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo;
//        ^^^
// [diag.undefinedGetterOnFunctionType] The getter 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  int get foo => 1;
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_propertyAccess_target_noPrefix_instantiated_getter_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo;
}

extension E on Type {
  int get foo => 1;
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_propertyAccess_target_noPrefix_instantiated_setter() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo = 7;
//        ^^^
// [diag.undefinedSetterOnFunctionType] The setter 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  set foo(int value) {}
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_propertyAccess_target_noPrefix_instantiated_setter_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');

    var node = result.findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);
var t = Fn<int>;
''');

    var node = result.findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_noPrefix_instantiated_tooFewTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T, U> = void Function(T, U);
var t = Fn<int>;
//        ^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'Fn' is declared with 2 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(dynamic, dynamic)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          dynamic
          dynamic
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_noPrefix_instantiated_tooManyTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);
var t = Fn<int, String>;
//        ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'Fn' is declared with 1 type parameters, but 2 type arguments were given.
''');

    var node = result.findNode.typeLiteral('Fn<int, String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(dynamic)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          dynamic
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_noPrefix_instantiated_typeArgumentsDoNotMatchBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn<T extends num> = void Function(T);
var t = Fn<String>;
//      ^^^^^^^^^^
// [context 1] The inverted type 'Fn<String>' is also not regular-bounded, so the type is not well-bounded.
//         ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
''');

    var node = result.findNode.typeLiteral('Fn<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: <testLibrary>::@typeAlias::Fn
    type: void Function(String)
      alias: <testLibrary>::@typeAlias::Fn
        typeArguments
          String
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_noPrefix_notInstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F = void Function();
var t = F;
''');

    var node = result.findNode.typeLiteral('F;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: F
    element: <testLibrary>::@typeAlias::F
    type: void Function()
      alias: <testLibrary>::@typeAlias::F
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_withPrefix_instantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.Fn<int>;
''');

    var node = result.findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::Fn
    type: void Function(int)
      alias: package:test/a.dart::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeAlias_variableDeclaration_initializer_withPrefix_notInstantiated() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.F;
''');

    var node = result.findNode.typeLiteral('F;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
    name: F
    element: package:test/a.dart::@typeAlias::F
    type: void Function()
      alias: package:test/a.dart::@typeAlias::F
  staticType: Type
''');
  }

  test_typeParameter_argumentList_argument() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f(Type t) {}
  void g() {
    f(T);
  }
}
''');

    var node = result.findNode.typeLiteral('T)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  correspondingParameter: <testLibrary>::@class::C::@method::f::@formalParameter::t
  staticType: Type
''');
  }

  test_typeParameter_argumentList_argument_hasTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f(Object? x) {}
  void g() {
    f(T<int>);
//    ^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
  }
}
''');

    // TODO(scheglov): This should be `TypeLiteral`.
    var node = result.findNode.functionReference('T<int>)');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: T
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  correspondingParameter: <testLibrary>::@class::C::@method::f::@formalParameter::x
  staticType: InvalidType
''');
  }

  test_typeParameter_assignmentExpression_rightHandSide() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  Type t = int;
  void f() {
    t = T;
  }
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  correspondingParameter: <testLibrary>::@class::C::@setter::t::@formalParameter::value
  staticType: Type
''');
  }

  test_typeParameter_binaryExpression_leftOperand() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f() {
    T == int;
  }
}
''');

    var node = result.findNode.typeLiteral('T ==');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_binaryExpression_rightOperand() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f() {
    int == T;
  }
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Type
''');
  }

  test_typeParameter_binaryExpression_rightOperand_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  Object? x;
  void f() {
    x ?? T;
  }
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  correspondingParameter: <null>
  staticType: Type
''');
  }

  test_typeParameter_expressionFunctionBody_expression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  Type f() => T;
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_expressionFunctionBody_expression_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  Type f() => (T);
}
''');

    var node = result.findNode.typeLiteral('T)');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_expressionStatement_expression_enum() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E<T> {
  v;
  void foo() {
    T;
  }
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_listLiteral_elements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var l = [T];
}
''');

    var node = result.findNode.typeLiteral('T]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_listLiteral_ifElement_else() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  List<Object> f(bool b) {
    return [if (b) int else T];
  }
}
''');

    var node = result.findNode.typeLiteral('T]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_listLiteral_nullAwareSpread() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var l = [...?T];
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//             ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');

    var node = result.findNode.typeLiteral('T]');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_localFunctionTypeParameter_variableDeclaration_initializer() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  void g<U>() {
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
    var x = U;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  }
}
''');

    var node = result.findNode.typeLiteral('U;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: U
    element: #E0 U
    type: U
  staticType: Type
''');
  }

  test_typeParameter_mapLiteral_ifElement_key_else() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f(bool b) {
    var m = {if (b) T: 1 else Never: 2};
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'm' isn't used.
  }
}
''');

    var node2 = result.findNode.typeLiteral('T: 1');
    assertResolvedNodeText(node2, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');

    var node3 = result.findNode.typeLiteral('Never: 2');
    assertResolvedNodeText(node3, r'''
TypeLiteral
  type: NamedType
    name: Never
    element: Never
    type: Never
  staticType: Type
''');
  }

  test_typeParameter_mapLiteral_key() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var m = {T: 1};
}
''');

    var node = result.findNode.typeLiteral('T: 1');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_mapLiteral_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var m = {1: T};
}
''');

    var node = result.findNode.typeLiteral('T}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_returnStatement_expression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  Type f() {
    return T;
  }
}
''');

    var node = result.findNode.typeLiteral('T;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_setLiteral_elements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var s = {T};
}
''');

    var node = result.findNode.typeLiteral('T}');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: Type
''');
  }

  test_typeParameter_variableDeclaration_initializer_hasTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  var t = T<int>;
//        ^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    // TODO(scheglov): This should be `TypeLiteral`.
    var node = result.findNode.functionReference('T<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: T
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_typeVariableTypeAlias_variableDeclaration_initializer_noPrefix_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef T<E> = E;
var t = T<int>;
''');

    var node = result.findNode.typeLiteral('T<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::T
    type: int
      alias: <testLibrary>::@typeAlias::T
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeVariableTypeAlias_variableDeclaration_initializer_noPrefix_instantiated_functionTypeArg() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef T<E> = E;
var t = T<void Function()>;
''');

    var node = result.findNode.typeLiteral('T<void Function()>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: void
            element: <null>
            type: void
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          declaredFragment: GenericFunctionTypeElement
            parameters
            returnType: void
            type: void Function()
          type: void Function()
      rightBracket: >
    element: <testLibrary>::@typeAlias::T
    type: void Function()
      alias: <testLibrary>::@typeAlias::T
        typeArguments
          void Function()
  staticType: Type
''');
  }
}

@reflectiveTest
class TypeLiteralResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_class() async {
    await resolveTestCodeWithDiagnostics('''
class C<T> {}
var t = C<int>;
//       ^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
''');
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
var t = a.C<int>;
//         ^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
''');
  }
}
