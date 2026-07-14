// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';
import '../../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Dart2InferenceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests for Dart2 inference rules back-ported from FrontEnd.
///
/// https://github.com/dart-lang/sdk/issues/31638
@reflectiveTest
class Dart2InferenceTest extends PubPackageResolutionTest {
  test_assertInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T foo<T>(int _) => throw 0;

class C {
  C() : assert(foo(0), foo(1));
}
''');

    var node = result.findNode.singleAssertInitializer;
    assertResolvedNodeText(node, r'''
AssertInitializer
  assertKeyword: assert
  leftParenthesis: (
  condition: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::foo::@formalParameter::_
            substitution: {T: bool}
          staticType: int
      rightParenthesis: )
    staticInvokeType: bool Function(int)
    staticType: bool
    typeArgumentTypes
      bool
  comma: ,
  message: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::foo::@formalParameter::_
            substitution: {T: dynamic}
          staticType: int
      rightParenthesis: )
    staticInvokeType: dynamic Function(int)
    staticType: dynamic
    typeArgumentTypes
      dynamic
  rightParenthesis: )
''');
  }

  test_assertStatement_message() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T foo<T>(int _) => throw 0;

void f() {
  assert(foo(0), foo(1));
}
''');

    var node = result.findNode.singleAssertStatement;
    assertResolvedNodeText(node, r'''
AssertStatement
  assertKeyword: assert
  leftParenthesis: (
  condition: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::foo::@formalParameter::_
            substitution: {T: bool}
          staticType: int
      rightParenthesis: )
    staticInvokeType: bool Function(int)
    staticType: bool
    typeArgumentTypes
      bool
  comma: ,
  message: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::foo::@formalParameter::_
            substitution: {T: dynamic}
          staticType: int
      rightParenthesis: )
    staticInvokeType: dynamic Function(int)
    staticType: dynamic
    typeArgumentTypes
      dynamic
  rightParenthesis: )
  semicolon: ;
''');
  }

  test_closure_downwardReturnType_arrow() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
  List<int> Function() g;
  g = () => 42;
//          ^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'List<int>' function, as required by the closure's context.
  g;
}
''');
    Expression closure = result.findNode.expression('() => 42');
    assertType(closure, 'List<int> Function()');
  }

  test_closure_downwardReturnType_block() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
  List<int> Function() g;
  g = () { // mark
    return 42;
//         ^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'List<int>' function, as required by the closure's context.
  };
  g;
}
''');
    Expression closure = result.findNode.expression('() { // mark');
    assertType(closure, 'List<int> Function()');
  }

  test_compoundAssignment_simpleIdentifier_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B operator +(int i) => this;
}

B get topLevel => new B();

void set topLevel(A value) {}

main() {
  var /*@type=B*/ v = topLevel += 1;
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
    _assertTypeAnnotations(result);
  }

  test_forIn_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>() => throw 0;

class A {}

late A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  late A aField;
  void set aSetter(A value) {}
  void test() {
    late A aLocal;
    for (aLocal in f()) {} // local
    aLocal;
    for (aField in f()) {} // field
    for (aSetter in f()) {} // setter
    for (aTopLevel in f()) {} // top variable
    for (aTopLevelSetter in f()) {} // top setter
  }
}''');
    void assertInvocationType(String prefix) {
      var invocation = result.findNode.methodInvocation(prefix);
      assertType(invocation, 'Iterable<A>');
    }

    assertInvocationType('f()) {} // local');
    assertInvocationType('f()) {} // field');
    assertInvocationType('f()) {} // setter');
    assertInvocationType('f()) {} // top variable');
    assertInvocationType('f()) {} // top setter');
  }

  test_forIn_variable_implicitlyTyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}

List<T> f<T extends A>(List<T> items) => items;

void test(List<A> listA, List<B> listB) {
  for (var a1 in f(listA)) {} // 1
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
  for (A a2 in f(listA)) {} // 2
//       ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
  for (var b1 in f(listB)) {} // 3
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'b1' isn't used.
  for (A b2 in f(listB)) {} // 4
//       ^^
// [diag.unusedLocalVariable] The value of the local variable 'b2' isn't used.
  for (B b3 in f(listB)) {} // 5
//       ^^
// [diag.unusedLocalVariable] The value of the local variable 'b3' isn't used.
}
''');
    void assertTypes(
      String vSearch,
      String vType,
      String fSearch,
      String fType,
    ) {
      var node = result.findNode.declaredIdentifier(vSearch);

      var element = node.declaredFragment?.element as LocalVariableElement;
      assertType(element.type, vType);

      var invocation = result.findNode.methodInvocation(fSearch);
      assertType(invocation, fType);
    }

    assertTypes('a1 in', 'A', 'f(listA)) {} // 1', 'List<A>');
    assertTypes('a2 in', 'A', 'f(listA)) {} // 2', 'List<A>');
    assertTypes('b1 in', 'B', 'f(listB)) {} // 3', 'List<B>');
    assertTypes('b2 in', 'A', 'f(listB)) {} // 4', 'List<A>');
    assertTypes('b3 in', 'B', 'f(listB)) {} // 5', 'List<B>');
  }

  test_implicitVoidReturnType_default() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set x(_) {}
  operator []=(int index, double value) => null;
}
''');
    ClassElement c = result.findElement.class_('C');

    SetterElement x = c.setters[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_implicitVoidReturnType_derived() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Base {
  dynamic set x(_) {}
//^^^^^^^
// [diag.nonVoidReturnForSetter] The return type of the setter must be 'void' or absent.
  dynamic operator[]=(int x, int y) => null;
//^^^^^^^
// [diag.nonVoidReturnForOperator] The return type of the operator []= must be 'void'.
}
class Derived extends Base {
  set x(_) {}
  operator[]=(int x, int y) {}
}''');
    ClassElement c = result.findElement.class_('Derived');

    SetterElement x = c.setters[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_listMap_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = [];
var y = {};
''');
    var xNode = result.findNode.variableDeclaration('x = ');
    var xfragment = xNode.declaredFragment!;
    assertType(xfragment.element.type, 'List<dynamic>');

    var yNode = result.findNode.variableDeclaration('y = ');
    var yfragment = yNode.declaredFragment!;
    assertType(yfragment.element.type, 'Map<dynamic, dynamic>');
  }

  test_listMap_null() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = [null];
var y = {null: null};
''');
    var xNode = result.findNode.variableDeclaration('x = ');
    var xFragment = xNode.declaredFragment!;
    assertType(xFragment.element.type, 'List<Null>');

    var yNode = result.findNode.variableDeclaration('y = ');
    var yFragment = yNode.declaredFragment!;
    assertType(yFragment.element.type, 'Map<Null, Null>');
  }

  test_logicalAnd() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T foo<T>() => throw 0;

void f() {
  foo() && foo();
}
''');

    var node = result.findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: &&
  rightOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_logicalOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T foo<T>() => throw 0;

void f() {
  foo() || foo();
}
''');

    var node = result.findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: ||
  rightOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_switchExpression_asContext_forCases() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      break;
    default:
      break;
  }
}''');
    var node = result.findNode.instanceCreation('C():');
    assertType(node, 'C<int>');
  }

  test_switchExpression_asContext_forCases_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      break;
    default:
      break;
  }
}''');
    var node = result.findNode.instanceCreation('const C():');
    assertType(node, 'C<int>');
  }

  test_voidType_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void m() {}
}
var x = new C().m();
main() {
  var y = new C().m();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
    var xNode = result.findNode.variableDeclaration('x = ');
    var xFragment = xNode.declaredFragment!;
    expect(xFragment.element.type, VoidTypeImpl.instance);

    var yNode = result.findNode.variableDeclaration('y = ');
    var yFragment = yNode.declaredFragment!;
    expect(yFragment.element.type, VoidTypeImpl.instance);
  }

  test_voidType_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {}
var x = f();
main() {
  var y = f();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
    var xNode = result.findNode.variableDeclaration('x = ');
    var xFragment = xNode.declaredFragment!;
    expect(xFragment.element.type, VoidTypeImpl.instance);

    var yNode = result.findNode.variableDeclaration('y = ');
    var yFragment = yNode.declaredFragment!;
    expect(yFragment.element.type, VoidTypeImpl.instance);
  }

  void _assertTypeAnnotations(TestResolvedUnitResult result) {
    var code = result.content;
    var unit = result.unit;

    var types = <int, String>{};
    {
      int lastIndex = 0;
      while (true) {
        const prefix = '/*@type=';
        int openIndex = code.indexOf(prefix, lastIndex);
        if (openIndex == -1) {
          break;
        }
        int closeIndex = code.indexOf('*/', openIndex + 1);
        expect(closeIndex, isPositive);
        types[openIndex] = code.substring(
          openIndex + prefix.length,
          closeIndex,
        );
        lastIndex = closeIndex;
      }
    }

    unit.accept2(
      FunctionAstVisitor(
        simpleIdentifier: (node) {
          var comment = node.token.precedingComments;
          if (comment != null) {
            var expectedType = types[comment.offset];
            if (expectedType != null) {
              var element = node.element as VariableElement;
              String actualType = typeString(element.type);
              expect(actualType, expectedType, reason: '@${comment.offset}');
            }
          }
        },
      ),
    );
  }
}
