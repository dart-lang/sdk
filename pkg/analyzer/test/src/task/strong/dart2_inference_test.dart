// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
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
    await assertNoErrorsInCode(r'''
T foo<T>(int _) => throw 0;

class C {
  C() : assert(foo(0), foo(1));
}
''');

    final node = findNode.singleAssertInitializer;
    assertResolvedNodeText(node, r'''
AssertInitializer
  assertKeyword: assert
  leftParenthesis: (
  condition: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          parameter: ParameterMember
            base: root::@parameter::_
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
      staticElement: self::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          parameter: ParameterMember
            base: root::@parameter::_
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
    await assertNoErrorsInCode(r'''
T foo<T>(int _) => throw 0;

void f() {
  assert(foo(0), foo(1));
}
''');

    final node = findNode.singleAssertStatement;
    assertResolvedNodeText(node, r'''
AssertStatement
  assertKeyword: assert
  leftParenthesis: (
  condition: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          parameter: ParameterMember
            base: root::@parameter::_
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
      staticElement: self::@function::foo
      staticType: T Function<T>(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          parameter: ParameterMember
            base: root::@parameter::_
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
    var code = r'''
void main() {
  List<int> Function() g;
  g = () => 42;
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() => 42');
    assertType(closure, 'List<int> Function()');
  }

  test_closure_downwardReturnType_block() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () { // mark
    return 42;
  };
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() { // mark');
    assertType(closure, 'List<int> Function()');
  }

  test_compoundAssignment_simpleIdentifier_topLevel() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  B operator +(int i) => this;
}

B get topLevel => new B();

void set topLevel(A value) {}

main() {
  var /*@type=B*/ v = topLevel += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 152, 1),
    ]);
    _assertTypeAnnotations();
  }

  test_forIn_identifier() async {
    var code = r'''
T f<T>() => null;

class A {}

A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  A aField;
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in f()) {} // local
    for (aField in f()) {} // field
    for (aSetter in f()) {} // setter
    for (aTopLevel in f()) {} // top variable
    for (aTopLevelSetter in f()) {} // top setter
  }
}''';
    await resolveTestCode(code);
    void assertInvocationType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertType(invocation, 'Iterable<A>');
    }

    assertInvocationType('f()) {} // local');
    assertInvocationType('f()) {} // field');
    assertInvocationType('f()) {} // setter');
    assertInvocationType('f()) {} // top variable');
    assertInvocationType('f()) {} // top setter');
  }

  test_forIn_variable_implicitlyTyped() async {
    var code = r'''
class A {}
class B extends A {}

List<T> f<T extends A>(List<T> items) => items;

void test(List<A> listA, List<B> listB) {
  for (var a1 in f(listA)) {} // 1
  for (A a2 in f(listA)) {} // 2
  for (var b1 in f(listB)) {} // 3
  for (A b2 in f(listB)) {} // 4
  for (B b3 in f(listB)) {} // 5
}
''';
    await resolveTestCode(code);
    void assertTypes(
        String vSearch, String vType, String fSearch, String fType) {
      var node = findNode.declaredIdentifier(vSearch);

      var element = node.declaredElement as LocalVariableElement;
      assertType(element.type, vType);

      var invocation = findNode.methodInvocation(fSearch);
      assertType(invocation, fType);
    }

    assertTypes('a1 in', 'A', 'f(listA)) {} // 1', 'List<A>');
    assertTypes('a2 in', 'A', 'f(listA)) {} // 2', 'List<A>');
    assertTypes('b1 in', 'B', 'f(listB)) {} // 3', 'List<B>');
    assertTypes('b2 in', 'A', 'f(listB)) {} // 4', 'List<A>');
    assertTypes('b3 in', 'B', 'f(listB)) {} // 5', 'List<B>');
  }

  test_implicitVoidReturnType_default() async {
    var code = r'''
class C {
  set x(_) {}
  operator []=(int index, double value) => null;
}
''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('C');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_implicitVoidReturnType_derived() async {
    var code = r'''
class Base {
  dynamic set x(_) {}
  dynamic operator[]=(int x, int y) => null;
}
class Derived extends Base {
  set x(_) {}
  operator[]=(int x, int y) {}
}''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('Derived');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_listMap_empty() async {
    var code = r'''
var x = [];
var y = {};
''';
    await resolveTestCode(code);
    var xNode = findNode.variableDeclaration('x = ');
    var xElement = xNode.declaredElement!;
    assertType(xElement.type, 'List<dynamic>');

    var yNode = findNode.variableDeclaration('y = ');
    var yElement = yNode.declaredElement!;
    assertType(yElement.type, 'Map<dynamic, dynamic>');
  }

  test_listMap_null() async {
    var code = r'''
var x = [null];
var y = {null: null};
''';
    await resolveTestCode(code);
    var xNode = findNode.variableDeclaration('x = ');
    var xElement = xNode.declaredElement!;
    assertType(xElement.type, 'List<Null>');

    var yNode = findNode.variableDeclaration('y = ');
    var yElement = yNode.declaredElement!;
    assertType(yElement.type, 'Map<Null, Null>');
  }

  test_logicalAnd() async {
    await assertNoErrorsInCode(r'''
T foo<T>() => throw 0;

void f() {
  foo() && foo();
}
''');

    final node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
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
      staticElement: self::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_logicalOr() async {
    await assertNoErrorsInCode(r'''
T foo<T>() => throw 0;

void f() {
  foo() || foo();
}
''');

    final node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: foo
      staticElement: self::@function::foo
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
      staticElement: self::@function::foo
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_switchExpression_asContext_forCases() async {
    var code = r'''
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
}''';
    await resolveTestCode(code);
    var node = findNode.instanceCreation('C():');
    assertType(node, 'C<int>');
  }

  test_switchExpression_asContext_forCases_language219() async {
    var code = r'''
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
}''';
    await resolveTestCode(code);
    var node = findNode.instanceCreation('const C():');
    assertType(node, 'C<int>');
  }

  test_voidType_method() async {
    var code = r'''
class C {
  void m() {}
}
var x = new C().m();
main() {
  var y = new C().m();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.variableDeclaration('x = ');
    var xElement = xNode.declaredElement!;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.variableDeclaration('y = ');
    var yElement = yNode.declaredElement!;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  test_voidType_topLevelFunction() async {
    var code = r'''
void f() {}
var x = f();
main() {
  var y = f();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.variableDeclaration('x = ');
    var xElement = xNode.declaredElement!;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.variableDeclaration('y = ');
    var yElement = yNode.declaredElement!;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  void _assertTypeAnnotations() {
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
        types[openIndex] =
            code.substring(openIndex + prefix.length, closeIndex);
        lastIndex = closeIndex;
      }
    }

    unit.accept(FunctionAstVisitor(
      simpleIdentifier: (node) {
        var comment = node.token.precedingComments;
        if (comment != null) {
          var expectedType = types[comment.offset];
          if (expectedType != null) {
            var element = node.staticElement as VariableElement;
            String actualType = typeString(element.type);
            expect(actualType, expectedType, reason: '@${comment.offset}');
          }
        }
      },
    ));
  }
}
