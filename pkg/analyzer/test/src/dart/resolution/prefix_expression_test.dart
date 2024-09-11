// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixExpressionResolutionTest);
  });
}

@reflectiveTest
class PrefixExpressionResolutionTest extends PubPackageResolutionTest {
  test_bang_bool_context() async {
    await assertNoErrorsInCode(r'''
T f<T>() {
  throw 42;
}

main() {
  !f();
}
''');

    var node = findNode.methodInvocation('f();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_bang_bool_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  !x;
}
''');

    var node = findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: bool
  staticElement: <null>
  staticType: bool
''');
  }

  test_bang_int_localVariable() async {
    await assertErrorsInCode(r'''
void f(int x) {
  !x;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 19, 1),
    ]);

    var node = findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: int
  staticElement: <null>
  staticType: bool
''');
  }

  test_bang_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  bool get foo => true;
}

void f(A? a) {
  !a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION,
          55, 6),
    ]);

    assertResolvedNodeText(findNode.prefix('!a'), r'''
PrefixExpression
  operator: !
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      staticType: bool
    staticType: bool?
  staticElement: <null>
  staticType: bool
''');
  }

  test_bang_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    !super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 28, 5),
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 28, 5),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SuperExpression
    superKeyword: super
    staticType: A
  staticElement: <null>
  staticType: bool
''');
  }

  test_formalParameter_inc_inc() async {
    await assertErrorsInCode(r'''
void f(int x) {
  ++ ++ x;
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 24, 1),
    ]);

    var node = findNode.prefix('++ ++ x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      staticType: null
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readType: int
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeType: int
    staticElement: dart:core::<fragment>::@class::num::@method::+
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_inc_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A a) {
  ++a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 28, 2),
    ]);

    var node = findNode.prefix('++a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readType: A
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeType: A
  staticElement: <null>
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
  ++a[0];
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
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
    ++super[0];
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_this() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    ++this[0];
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_unresolvedIdentifier() async {
    await assertErrorsInCode(r'''
void f() {
  ++x;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 1),
    ]);

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_minus_augmentedExpression_augments_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int foo = -augmented;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@field::foo
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  staticType: int
''');
  }

  test_minus_augmentedExpression_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int get foo => 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int get foo {
    return -augmented;
  }
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@getter::foo
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  staticType: int
''');
  }

  test_minus_augmentedExpression_augments_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment void foo() {
    -augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR, 65, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::foo
    staticType: A
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_minus_augmentedExpression_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  set foo(int _) {}
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment set foo(int _) {
    -augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER, 69, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@setter::foo
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_minus_augmentedExpression_augments_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int operator-() => 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int operator-() {
    return -augmented;
  }
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::unary-
    staticType: A
  staticElement: package:test/a.dart::<fragment>::@class::A::@method::unary-
  staticType: int
''');
  }

  test_minus_dynamicIdentifier() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  -a;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_minus_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  -a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertResolvedNodeText(findNode.prefix('-a'), r'''
PrefixExpression
  operator: -
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  staticType: int
''');
  }

  test_minus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  -x;
}
''');

    var node = findNode.prefix('-x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  staticType: int
''');
  }

  test_plusPlus_depromote() async {
    await assertNoErrorsInCode(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    ++x;
  }
}
''');

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readType: A
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeType: Object
  staticElement: <testLibraryFragment>::@class::A::@method::+
  staticType: Object
''');
  }

  test_plusPlus_notLValue_extensionOverride() async {
    await assertErrorsInCode(r'''
class C {}

extension Ext on C {
  int operator +(int _) {
    return 0;
  }
}

void f(C c) {
  ++Ext(c);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 103, 1),
    ]);

    var node = findNode.prefix('++Ext');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: ExtensionOverride
    name: Ext
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::c
          staticType: C
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::Ext
    extendedType: C
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <testLibraryFragment>::@extension::Ext::@method::+
  staticType: InvalidType
''');
  }

  test_plusPlus_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  ++int;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 15, 3),
    ]);

    var node = findNode.prefix('++int');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  readElement: dart:core::<fragment>::@class::int
  readType: InvalidType
  writeElement: dart:core::<fragment>::@class::int
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  ++a?.foo;
}
''');

    assertResolvedNodeText(findNode.prefix('++a'), r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int?
''');
  }

  test_plusPlus_ofExtensionType() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  ++a.foo;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@extensionType::A::@getter::foo
  readType: int
  writeElement: <testLibraryFragment>::@extensionType::A::@setter::foo
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f(A a) {
  ++a.x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  ++p.x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  readElement: package:test/a.dart::<fragment>::@getter::x
  readType: int
  writeElement: package:test/a.dart::<fragment>::@setter::x
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f() {
  ++A().x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibraryFragment>::@class::A
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_super() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++super.x;
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_this() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++this.x;
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readType: double
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeType: double
  staticElement: dart:core::<fragment>::@class::double::@method::+
  staticType: double
''');
  }

  test_plusPlus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readType: int
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readType: num
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_parameter_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T extends num>(T x) {
  ++x;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 31, 3),
    ]);

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readType: T
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeType: T
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_superSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@class::B::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_thisSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter_fromClass() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    ++super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 29, 5),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SuperExpression
    superKeyword: super
    staticType: A
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_switchExpression() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  ++switch (x) {
    _ => 0,
  };
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 51, 1),
    ]);

    var node = findNode.prefix('++switch');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  /// Verify that we get all necessary types when building the dependencies
  /// graph during top-level inference.
  test_plusPlus_topLevelInference() async {
    await assertNoErrorsInCode(r'''
var x = 0;

class A {
  final y = ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  readElement: <testLibraryFragment>::@getter::x
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
  }

  test_tilde_augmentedExpression_augments_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int operator-() => 0;
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int operator-() {
    return ~augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR, 77, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::unary-
    staticType: A
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_tilde_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  ~a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertResolvedNodeText(findNode.prefix('~a'), r'''
PrefixExpression
  operator: ~
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  staticElement: dart:core::<fragment>::@class::int::@method::~
  staticType: int
''');
  }

  test_tilde_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ~x;
}
''');

    var node = findNode.prefix('~x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::~
  staticType: int
''');
  }
}
