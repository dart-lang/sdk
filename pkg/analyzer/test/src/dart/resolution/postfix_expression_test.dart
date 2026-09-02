// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceUpdate4Test);
    defineReflectiveTests(NullAssertionExpressionResolutionTest);
    defineReflectiveTests(PostfixIncrementOrDecrementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InferenceUpdate4Test extends PubPackageResolutionTest {
  test_isExpression_notPromoted() async {
    var result = await resolveTestCodeWithDiagnostics('''
f() {
  num x = 2;
  if ((x++) is int) {
    x;
  }
}
''');
    var node = result.findNode.simple('x;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: x
  element: x@12
  staticType: num
''');
    assertType(node, 'num');
  }
}

@reflectiveTest
class NullAssertionExpressionResolutionTest extends PubPackageResolutionTest {
  test_nullCheck() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x!;
}
''');

    var node = result.findNode.nullAssertion('x!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  operator: !
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  operator: !
  element: <null>
  staticType: int
''');
  }

  test_nullCheck_functionExpressionInvocation_rewrite() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Function f2) {
  f2(42)!;
}
''');
  }

  test_nullCheck_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<String, int> a) {
  int v = a['foo']!;
  v;
}
''');

    var node1 = result.findNode.receiverIndexExpression('a[');
    assertResolvedNodeText(node1, r'''
ReceiverIndexExpression
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Map<String, int>
  leftBracket: [
  index: SimpleStringLiteral
    literal: 'foo'
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: SubstitutedMethodElementImpl
      baseElement: dart:core::@class::Map::@method::[]
      substitution: {K: String, V: int}
    invokeType: int? Function(Object?)
    type: int?
  staticType: int?
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Map<String, int>
  leftBracket: [
  index: SimpleStringLiteral
    literal: 'foo'
  rightBracket: ]
  element: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::Map::@method::[]
    substitution: {K: String, V: int}
  staticType: int?
''');

    var node2 = result.findNode.nullAssertion(']!');
    assertResolvedNodeText(node2, r'''
NullAssertionExpression
  operand: ReceiverIndexExpression
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: Map<String, int>
    leftBracket: [
    index: SimpleStringLiteral
      literal: 'foo'
    rightBracket: ]
    resolution: MethodIndexReadResolution
      element: SubstitutedMethodElementImpl
        baseElement: dart:core::@class::Map::@method::[]
        substitution: {K: String, V: int}
      invokeType: int? Function(Object?)
      type: int?
    staticType: int?
  operator: !
  staticType: int
V1: PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: Map<String, int>
    leftBracket: [
    index: SimpleStringLiteral
      literal: 'foo'
    rightBracket: ]
    element: SubstitutedMethodElementImpl
      baseElement: dart:core::@class::Map::@method::[]
      substitution: {K: String, V: int}
    staticType: int?
  operator: !
  element: <null>
  staticType: int
''');
  }

  test_nullCheck_interfaceType_viaAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = String;

void f(A? x) {
  x!;
}
''');

    var node = result.findNode.nullAssertion('x!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: String?
      alias: <testLibrary>::@typeAlias::A
        nullabilitySuffix: NullabilitySuffix.question
  operator: !
  staticType: String
    alias: <testLibrary>::@typeAlias::A
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: String?
      alias: <testLibrary>::@typeAlias::A
        nullabilitySuffix: NullabilitySuffix.question
  operator: !
  element: <null>
  staticType: String
    alias: <testLibrary>::@typeAlias::A
''');
  }

  test_nullCheck_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null x) {
  x!;
//^^
// [diag.nullCheckAlwaysFails] This null-check will always throw an exception because the expression will always evaluate to 'null'.
}
''');

    assertType(result.findNode.nullAssertion('x!'), 'Never');
  }

  test_nullCheck_nullableContext() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>(T t) => t;

int g() => f(null)!;
''');

    var node = result.findNode.nullAssertion('f(null)!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: UnqualifiedFunctionInvocation
    name: f
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        NullLiteral
          literal: null
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::f
      invokeType: int? Function(int?)
      type: int?
    staticType: int?
    typeArgumentTypes
      int?
  operator: !
  staticType: int
V1: PostfixExpression
  operand: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    staticInvokeType: int? Function(int?)
    staticType: int?
    typeArgumentTypes
      int?
  operator: !
  element: <null>
  staticType: int
''');
  }

  /// See https://github.com/dart-lang/language/issues/1163
  test_nullCheck_participatesNullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int zero;
  int? zeroOrNull;

  A(this.zero, [this.zeroOrNull]);
}

void test1(A? a) => a?.zero!;
//                         ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
void test2(A? a) => a?.zeroOrNull!;
void test3(A? a) => a?.zero!.isEven;
//                         ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
void test4(A? a) => a?.zeroOrNull!.isEven;

class Foo {
  Bar? bar;

  Foo(this.bar);

  Bar? operator [](int? index) => null;
}

class Bar {
  int baz;

  Bar(this.baz);

  int operator [](int index) => index;
}

void test5(Foo? foo) => foo?.bar!;
void test6(Foo? foo) => foo?.bar!.baz;
void test7(Foo? foo, int a) => foo?.bar![a];
void test8(Foo? foo, int? a) => foo?[a]!;
void test9(Foo? foo, int? a) => foo?[a]!.baz;
void test10(Foo? foo, int? a, int b) => foo?[a]![b];
''');

    void assertTestType(int index, String expected) {
      var function = result.findNode.functionDeclaration('test$index(');
      var body = function.functionExpression.body as ExpressionFunctionBody;
      assertType(body.expression2, expected);
    }

    assertTestType(1, 'int?');
    assertTestType(2, 'int?');
    assertTestType(3, 'bool?');
    assertTestType(4, 'bool?');

    assertTestType(5, 'Bar?');
    assertTestType(6, 'int?');
    assertTestType(7, 'int?');
    assertTestType(8, 'Bar?');
    assertTestType(9, 'int?');
    assertTestType(10, 'int?');
  }

  test_nullCheck_recordType_viaAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int,);

void f(A? x) {
  x!;
}
''');

    var node = result.findNode.nullAssertion('x!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int,)?
      alias: <testLibrary>::@typeAlias::A
        nullabilitySuffix: NullabilitySuffix.question
  operator: !
  staticType: (int,)
    alias: <testLibrary>::@typeAlias::A
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int,)?
      alias: <testLibrary>::@typeAlias::A
        nullabilitySuffix: NullabilitySuffix.question
  operator: !
  element: <null>
  staticType: (int,)
    alias: <testLibrary>::@typeAlias::A
''');
  }

  test_nullCheck_superExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
}

class B extends A {
  void bar() {
    super!.foo();
//  ^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target2: NullAssertionExpression
    operand: SuperExpression
      superKeyword: super
      staticType: dynamic
    operator: !
    staticType: dynamic
  target(v1): PostfixExpression
    operand: SuperExpression
      superKeyword: super
      staticType: dynamic
    operator: !
    element: <null>
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_nullCheck_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>(T? x) {
  x!;
}
''');

    var node = result.findNode.nullAssertion('x!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: T?
  operator: !
  staticType: T & Object
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: T?
  operator: !
  element: <null>
  staticType: T & Object
''');
  }

  test_nullCheck_typeParameter_already_promoted() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T>(T? x) {
  if (x is num?) {
    x!;
  }
}
''');

    var node = result.findNode.nullAssertion('x!');
    assertResolvedNodeText(node, r'''
NullAssertionExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (T & num?)?
  operator: !
  staticType: T & num
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (T & num?)?
  operator: !
  element: <null>
  staticType: T & num
''');
  }
}

@reflectiveTest
class PostfixIncrementOrDecrementResolutionTest
    extends PubPackageResolutionTest {
  test_dec_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x--;
}
''');

    var node = result.findNode.postfixDecrement('x--');
    assertResolvedNodeText(node, r'''
PostfixDecrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: int
  operator: --
  element: dart:core::@class::num::@method::-
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: --
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::-
  staticType: int
''');
  }

  test_formalParameter_inc_inc() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x ++ ++;
//     ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.postfixIncrement('++;');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: InvalidExpressionAssignmentTarget
    expression: PostfixIncrement
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: int
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: int
      operator: ++
      element: dart:core::@class::num::@method::+
      operatorResultType: int
      staticType: int
  operator: ++
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: int
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: int
    element: dart:core::@class::num::@method::+
    staticType: int
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_incUnresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A a) {
  a++;
// ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.postfixIncrement('++;');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      acceptedType: A
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: A
V1: PostfixExpression
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: A
  element: <null>
  staticType: A
''');
  }

  test_inc_dynamicIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  x++;
}
''');

    var node = result.findNode.singlePostfixIncrement;
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: dynamic
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: dynamic
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: dynamic
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_inc_formalParameter_inc() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ++x++;
//   ^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: InvalidExpressionAssignmentTarget
    expression: PostfixIncrement
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: int
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: int
      operator: ++
      element: dart:core::@class::num::@method::+
      operatorResultType: int
      staticType: int
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: int
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: int
    element: dart:core::@class::num::@method::+
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_indexExpression_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0]++;
}
''');

    var node = result.findNode.postfixIncrement('a[0]++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_instance_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A? a) {
  a?[0]++;
}
''');

    var node = result.findNode.postfixIncrement('a?[0]++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int?
V1: PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_inc_indexExpression_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0]++;
  }
}
''');

    var node = result.findNode.postfixIncrement('[0]++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverIndexAssignmentTarget
    receiver: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0]++;
  }
}
''');

    var node = result.findNode.postfixIncrement('[0]++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverIndexAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_notLValue_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (0)++;
//   ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.postfixIncrement('(0)++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: InvalidExpressionAssignmentTarget
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression2: IntegerLiteral
        literal: 0
        staticType: int
      rightParenthesis: )
      staticType: int
  operator: ++
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int++;
//^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.postfixIncrement('int++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: int
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: ++
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>() {
  T++;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.postfixIncrement('T++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: T
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: #E0 T
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: #E0 T
      recovery: <null>
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: T
    element: <null>
    staticType: null
  operator: ++
  readElement: #E0 T
  readType: InvalidType
  writeElement: #E0 T
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_ofExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  a.foo++;
}
''');

    var node = result.findNode.singlePostfixIncrement;
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extensionType::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@extensionType::A::@setter::foo
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@extensionType::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_prefixedIdentifier_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f(A a) {
  a.x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f() {
  A().x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  a?.foo++;
}
''');

    var node = result.findNode.postfixIncrement('foo++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int?
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_inc_propertyAccess_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x++;
  }
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    this.x++;
  }
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_parameter_depromote() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    x++;
    x; // ref
  }
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: A
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: Object
  operator: ++
  element: <testLibrary>::@class::A::@method::+
  operatorResultType: Object
  staticType: A
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <testLibrary>::@class::A::@method::+
  staticType: A
''');

    assertType(result.findNode.simple('x; // ref'), 'Object');
  }

  test_inc_simpleIdentifier_parameter_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: double
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: double
  operator: ++
  element: dart:core::@class::double::@method::+
  operatorResultType: double
  staticType: double
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: double
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_inc_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: int
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_parameter_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: num
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: num
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_inc_simpleIdentifier_thisGetter_superSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    x++;
  }
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::B::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::B::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_topGetter_topSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

void f() {
  x++;
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_topGetter_topSetter_fromClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    x++;
  }
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  operator: ++
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super++;
//       ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  }
}
''');

    var node = result.findNode.singlePostfixIncrement;
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: InvalidExpressionAssignmentTarget
    expression: SuperExpression
      superKeyword: super
      staticType: A
  operator: ++
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: SuperExpression
    superKeyword: super
    staticType: A
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  }++);
// ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.postfixIncrement('++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: InvalidExpressionAssignmentTarget
    expression: SwitchExpression
      switchKeyword: switch
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: Object?
      rightParenthesis: )
      leftBracket: {
      cases
        SwitchExpressionCase
          guardedPattern: GuardedPattern
            pattern: WildcardPattern
              name: _
              matchedValueType: Object?
          arrow: =>
          expression2: IntegerLiteral
            literal: 0
            staticType: int
      rightBracket: }
      staticType: int
  operator: ++
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_unresolvedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  x++;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.singlePostfixIncrement;
    assertResolvedNodeText(node, r'''
PostfixIncrement
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }
}
