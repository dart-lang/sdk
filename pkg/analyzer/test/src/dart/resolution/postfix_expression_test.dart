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
    defineReflectiveTests(PostfixExpressionResolutionTest);
  });
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: --
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::-
  element: dart:core::<fragment>::@class::num::@method::-#element
  staticType: int
''');
  }

  test_formalParameter_inc_inc() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x ++ ++;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 23, 2),
    ]);

    var node = findNode.postfix('++;');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: int
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: int
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: int
  operator: ++
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_incUnresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A a) {
  a++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 29, 2),
    ]);

    var node = findNode.postfix('++;');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: A
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: A
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: dynamic
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: dynamic
  staticElement: <null>
  element: <null>
  staticType: dynamic
''');
  }

  test_inc_formalParameter_inc() async {
    await assertErrorsInCode(r'''
void f(int x) {
  ++x++;
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 21, 2),
    ]);

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PostfixExpression
    operand: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: int
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: int
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_inc_notLValue_parenthesized() async {
    await assertErrorsInCode(r'''
void f() {
  (0)++;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 16, 2),
    ]);

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
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  int++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var node = findNode.postfix('int++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: int
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: dart:core::<fragment>::@class::int
  readElement2: dart:core::<fragment>::@class::int#element
  readType: InvalidType
  writeElement: dart:core::<fragment>::@class::int
  writeElement2: dart:core::<fragment>::@class::int#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_notLValue_simpleIdentifier_typeLiteral_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T>() {
  T++;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 16, 1),
    ]);

    var node = findNode.postfix('T++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: T
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: T@7
  readElement2: <not-implemented>
  readType: InvalidType
  writeElement: T@7
  writeElement2: <not-implemented>
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@extensionType::A::@getter::foo
  readElement2: <testLibraryFragment>::@extensionType::A::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@extensionType::A::@setter::foo
  writeElement2: <testLibraryFragment>::@extensionType::A::@setter::foo#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::<fragment>::@getter::x
  readElement2: package:test/a.dart::<fragment>::@getter::x#element
  readType: int
  writeElement: package:test/a.dart::<fragment>::@setter::x
  writeElement2: package:test/a.dart::<fragment>::@setter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@getter::foo
  readElement2: <testLibraryFragment>::@class::A::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: A
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: Object
  staticElement: <testLibraryFragment>::@class::A::@method::+
  element: <testLibraryFragment>::@class::A::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: double
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: double
  staticElement: dart:core::<fragment>::@class::double::@method::+
  element: dart:core::<fragment>::@class::double::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: num
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@class::B::@getter::x
  readElement2: <testLibraryFragment>::@class::B::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@getter::x
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@getter::x
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_inc_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    super++;
  }
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 32, 2),
    ]);

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SuperExpression
    superKeyword: super
    staticType: A
  operator: ++
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_switchExpression() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  }++);
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 51, 2),
    ]);

    var node = findNode.postfix('++');
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
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
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_unresolvedIdentifier() async {
    await assertErrorsInCode(r'''
void f() {
  x++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var node = findNode.singlePostfixExpression;
    assertResolvedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ++
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: int?
  operator: !
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Map<String, int>
  leftBracket: [
  index: SimpleStringLiteral
    literal: 'foo'
  rightBracket: ]
  staticElement: MethodMember
    base: dart:core::<fragment>::@class::Map::@method::[]
    substitution: {K: String, V: int}
  element: dart:core::<fragment>::@class::Map::@method::[]#element
  staticType: int?
''');

    assertResolvedNodeText(findNode.postfix(']!'), r'''
PostfixExpression
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: Map<String, int>
    leftBracket: [
    index: SimpleStringLiteral
      literal: 'foo'
    rightBracket: ]
    staticElement: MethodMember
      base: dart:core::<fragment>::@class::Map::@method::[]
      substitution: {K: String, V: int}
    element: dart:core::<fragment>::@class::Map::@method::[]#element
    staticType: int?
  operator: !
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: String?
      alias: <testLibraryFragment>::@typeAlias::A
  operator: !
  staticElement: <null>
  element: <null>
  staticType: String
    alias: <testLibraryFragment>::@typeAlias::A
''');
  }

  test_nullCheck_null() async {
    await assertErrorsInCode('''
void f(Null x) {
  x!;
}
''', [
      error(WarningCode.NULL_CHECK_ALWAYS_FAILS, 19, 2),
    ]);

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
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          parameter: ParameterMember
            base: <testLibraryFragment>::@function::f::@parameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    staticInvokeType: int? Function(int?)
    staticType: int?
    typeArgumentTypes
      int?
  operator: !
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  /// See https://github.com/dart-lang/language/issues/1163
  test_nullCheck_participatesNullShorting() async {
    await assertErrorsInCode('''
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
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 107, 1),
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 173, 1),
    ]);

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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: (int,)?
      alias: <testLibraryFragment>::@typeAlias::A
  operator: !
  staticElement: <null>
  element: <null>
  staticType: (int,)
    alias: <testLibraryFragment>::@typeAlias::A
''');
  }

  test_nullCheck_superExpression() async {
    await assertErrorsInCode(r'''
class A {
  int foo() => 0;
}

class B extends A {
  void bar() {
    super!.foo();
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 70, 6),
    ]);

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PostfixExpression
    operand: SuperExpression
      superKeyword: super
      staticType: dynamic
    operator: !
    staticElement: <null>
    element: <null>
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: T?
  operator: !
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: (T & num?)?
  operator: !
  staticElement: <null>
  element: <null>
  staticType: T & num
''');
  }
}
