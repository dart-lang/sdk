// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceUpdate4Test);
    defineReflectiveTests(PostfixExpressionResolutionTest);
  });
}

@reflectiveTest
class InferenceUpdate4Test extends PubPackageResolutionTest {
  test_isExpression_notPromoted() async {
    await assertNoErrorsInCode('''
f() {
  num x = 2;
  if ((x++) is int) {
    x;
  }
}
''');
    var nonPromotedIdentifier = findNode.simple('x;');
    assertResolvedNodeText(nonPromotedIdentifier, r'''
SimpleIdentifier
  token: x
  element: x@12
  staticType: num
''');
    assertType(nonPromotedIdentifier, 'num');
  }
}

@reflectiveTest
class PostfixExpressionResolutionTest extends PubPackageResolutionTest {
  test_dec_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x--;
}
''');

    var node = findNode.postfix('x--');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: --
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::-
  staticType: int
''');
  }

  test_formalParameter_inc_inc() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  x ++ ++;
}
''',
      [error(ParserErrorCode.illegalAssignmentToNonAssignable, 23, 2)],
    );

    var node = findNode.postfix('++;');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: int
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: int
    element: dart:core::@class::num::@method::+
    staticType: int
  operator: ++
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_incUnresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A a) {
  a++;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 29, 2)],
    );

    var node = findNode.postfix('++;');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::a
  readType: A
  writeElement2: <testLibrary>::@function::f::@formalParameter::a
  writeType: A
  element: <null>
  staticType: A
''');
  }

  test_inc_dynamicIdentifier() async {
    await assertNoErrorsInCode(r'''
void f(dynamic x) {
  x++;
}
''');

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: dynamic
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_inc_formalParameter_inc() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  ++x++;
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 21, 2)],
    );

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: int
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: int
    element: dart:core::@class::num::@method::+
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_indexExpression_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0]++;
}
''');

    var node = findNode.postfix('a[0]++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_super() async {
    await assertNoErrorsInCode(r'''
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

    var node = findNode.postfix('[0]++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_this() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0]++;
  }
}
''');

    var node = findNode.postfix('[0]++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_notLValue_parenthesized() async {
    await assertErrorsInCode(
      r'''
void f() {
  (0)++;
}
''',
      [error(ParserErrorCode.illegalAssignmentToNonAssignable, 16, 2)],
    );

    var node = findNode.postfix('(0)++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: ++
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(
      r'''
void f() {
  int++;
}
''',
      [error(CompileTimeErrorCode.assignmentToType, 13, 3)],
    );

    var node = findNode.postfix('int++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: ++
  readElement2: dart:core::@class::int
  readType: InvalidType
  writeElement2: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral_typeParameter() async {
    await assertErrorsInCode(
      r'''
void f<T>() {
  T++;
}
''',
      [error(CompileTimeErrorCode.assignmentToType, 16, 1)],
    );

    var node = findNode.postfix('T++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: T
    element: <null>
    staticType: null
  operator: ++
  readElement2: #E0 T
  readType: InvalidType
  writeElement2: #E0 T
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_ofExtensionType() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  a.foo++;
}
''');

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@extensionType::A::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_prefixedIdentifier_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f(A a) {
  a.x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement2: package:test/a.dart::@getter::x
  readType: int
  writeElement2: package:test/a.dart::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f() {
  A().x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
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
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  a?.foo++;
}
''');

    assertResolvedNodeText(findNode.postfix('foo++'), r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_inc_propertyAccess_super() async {
    await assertNoErrorsInCode(r'''
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

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_propertyAccess_this() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    this.x++;
  }
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_parameter_depromote() async {
    await assertNoErrorsInCode(r'''
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

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: A
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <testLibrary>::@class::A::@method::+
  staticType: A
''');

    assertType(findNode.simple('x; // ref'), 'Object');
  }

  test_inc_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: double
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_inc_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: num
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_inc_simpleIdentifier_thisGetter_superSetter() async {
    await assertNoErrorsInCode(r'''
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

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@class::B::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  x++;
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@getter::x
  readType: int
  writeElement2: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_simpleIdentifier_topGetter_topSetter_fromClass() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    x++;
  }
}
''');

    var node = findNode.postfix('x++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@getter::x
  readType: int
  writeElement2: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    super++;
  }
}
''',
      [error(ParserErrorCode.illegalAssignmentToNonAssignable, 32, 2)],
    );

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SuperExpression
    superKeyword: super
    staticType: A
  operator: ++
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_switchExpression() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  }++);
}
''',
      [error(ParserErrorCode.illegalAssignmentToNonAssignable, 51, 2)],
    );

    var node = findNode.postfix('++');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_unresolvedIdentifier() async {
    await assertErrorsInCode(
      r'''
void f() {
  x++;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 13, 1)],
    );

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ++
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x!;
}
''');

    assertResolvedNodeText(findNode.postfix('x!'), r'''
PostfixExpression
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
    await assertNoErrorsInCode(r'''
void f(Function f2) {
  f2(42)!;
}
''');
  }

  test_nullCheck_indexExpression() async {
    await assertNoErrorsInCode(r'''
void f(Map<String, int> a) {
  int v = a['foo']!;
  v;
}
''');

    assertResolvedNodeText(findNode.index('a['), r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Map<String, int>
  leftBracket: [
  index: SimpleStringLiteral
    literal: 'foo'
  rightBracket: ]
  element: MethodMember
    baseElement: dart:core::@class::Map::@method::[]
    substitution: {K: String, V: int}
  staticType: int?
''');

    assertResolvedNodeText(findNode.postfix(']!'), r'''
PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: Map<String, int>
    leftBracket: [
    index: SimpleStringLiteral
      literal: 'foo'
    rightBracket: ]
    element: MethodMember
      baseElement: dart:core::@class::Map::@method::[]
      substitution: {K: String, V: int}
    staticType: int?
  operator: !
  element: <null>
  staticType: int
''');
  }

  test_nullCheck_interfaceType_viaAlias() async {
    await assertNoErrorsInCode(r'''
typedef A = String;

void f(A? x) {
  x!;
}
''');

    var node = findNode.postfix('x!');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: String?
      alias: <testLibrary>::@typeAlias::A
  operator: !
  element: <null>
  staticType: String
    alias: <testLibrary>::@typeAlias::A
''');
  }

  test_nullCheck_null() async {
    await assertErrorsInCode(
      '''
void f(Null x) {
  x!;
}
''',
      [error(WarningCode.nullCheckAlwaysFails, 19, 2)],
    );

    assertType(findNode.postfix('x!'), 'Never');
  }

  test_nullCheck_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null)!;
''');

    var node = findNode.postfix('f(null)!');
    assertResolvedNodeText(node, r'''
PostfixExpression
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
          correspondingParameter: ParameterMember
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
    await assertErrorsInCode(
      '''
class A {
  int zero;
  int? zeroOrNull;

  A(this.zero, [this.zeroOrNull]);
}

void test1(A? a) => a?.zero!;
void test2(A? a) => a?.zeroOrNull!;
void test3(A? a) => a?.zero!.isEven;
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
''',
      [
        error(StaticWarningCode.unnecessaryNonNullAssertion, 107, 1),
        error(StaticWarningCode.unnecessaryNonNullAssertion, 173, 1),
      ],
    );

    void assertTestType(int index, String expected) {
      var function = findNode.functionDeclaration('test$index(');
      var body = function.functionExpression.body as ExpressionFunctionBody;
      assertType(body.expression, expected);
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
    await assertNoErrorsInCode(r'''
typedef A = (int,);

void f(A? x) {
  x!;
}
''');

    var node = findNode.postfix('x!');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int,)?
      alias: <testLibrary>::@typeAlias::A
  operator: !
  element: <null>
  staticType: (int,)
    alias: <testLibrary>::@typeAlias::A
''');
  }

  test_nullCheck_superExpression() async {
    await assertErrorsInCode(
      r'''
class A {
  int foo() => 0;
}

class B extends A {
  void bar() {
    super!.foo();
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 70, 6)],
    );

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PostfixExpression
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
    await assertNoErrorsInCode(r'''
void f<T>(T? x) {
  x!;
}
''');

    var postfixExpression = findNode.postfix('x!');
    assertResolvedNodeText(postfixExpression, r'''
PostfixExpression
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
    await assertNoErrorsInCode('''
void f<T>(T? x) {
  if (x is num?) {
    x!;
  }
}
''');

    var postfixExpression = findNode.postfix('x!');
    assertResolvedNodeText(postfixExpression, r'''
PostfixExpression
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
