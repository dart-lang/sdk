// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixExpressionResolutionTest extends PubPackageResolutionTest {
  test_bang_bool_context() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>() {
  throw 42;
}

main() {
  !f();
}
''');

    var node = result.findNode.methodInvocation('f();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  !x;
}
''');

    var node = result.findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: bool
  element: <null>
  staticType: bool
''');
  }

  test_bang_int_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  !x;
// ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');

    var node = result.findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: <null>
  staticType: bool
''');
  }

  test_bang_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool get foo => true;
}

void f(A? a) {
  !a?.foo;
// ^^^^^^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');

    var node = result.findNode.prefix('!a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: bool
    staticType: bool?
  element: <null>
  staticType: bool
''');
  }

  test_bang_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    !super;
//   ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
  }
}
''');

    var node = result.findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SuperExpression
    superKeyword: super
    staticType: A
  element: <null>
  staticType: bool
''');
  }

  test_formalParameter_inc_inc() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ++ ++ x;
//      ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefix('++ ++ x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
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

  test_formalParameter_inc_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A a) {
  ++a;
//^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.prefix('++a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: A
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
  ++a[0];
}
''');

    var node = result.findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
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
    ++super[0];
  }
}
''');

    var node = result.findNode.prefix('++');
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
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
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
    ++this[0];
  }
}
''');

    var node = result.findNode.prefix('++');
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
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_unresolvedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  ++x;
//  ^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_minus_dynamicIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  -a;
}
''');

    var node = result.findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_minus_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  -a?.foo;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.prefix('-a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  element: dart:core::@class::int::@method::unary-
  staticType: int
''');
  }

  test_minus_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  -x;
}
''');

    var node = result.findNode.prefix('-x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: dart:core::@class::int::@method::unary-
  staticType: int
''');
  }

  test_plusPlus_depromote() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    ++x;
  }
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <testLibrary>::@class::A::@method::+
  staticType: Object
''');
  }

  test_plusPlus_notLValue_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension Ext on C {
  int operator +(int _) {
    return 0;
  }
}

void f(C c) {
  ++Ext(c);
//       ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefix('++Ext');
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
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::c
          staticType: C
      rightParenthesis: )
    element: <testLibrary>::@extension::Ext
    extendedType: C
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <testLibrary>::@extension::Ext::@method::+
  staticType: InvalidType
''');
  }

  test_plusPlus_notLValue_simpleIdentifier_typeLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  ++int;
//  ^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.prefix('++int');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  ++a?.foo;
}
''');

    var node = result.findNode.prefix('++a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_plusPlus_ofExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  ++a.foo;
}
''');

    var node = result.findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <testLibrary>::@extensionType::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f(A a) {
  ++a.x;
}
''');

    var node = result.findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  ++p.x;
}
''');

    var node = result.findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f() {
  ++A().x;
}
''');

    var node = result.findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.prefix('++');
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
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++this.x;
  }
}
''');

    var node = result.findNode.prefix('++');
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
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  ++x;
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: double
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_plusPlus_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ++x;
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  ++x;
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: num
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_parameter_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T x) {
  ++x;
//^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: T
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: T
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_superSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::B::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_thisSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
  void f() {
    ++x;
  }
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

void f() {
  ++x;
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter_fromClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    ++x;
  }
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    ++super;
//    ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singlePrefixExpression;
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
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  ++switch (x) {
    _ => 0,
  };
//^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefix('++switch');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Verify that we get all necessary types when building the dependencies
  /// graph during top-level inference.
  test_plusPlus_topLevelInference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 0;

class A {
  final y = ++x;
}
''');

    var node = result.findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_tilde_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  ~a?.foo;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '~' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.prefix('~a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  element: dart:core::@class::int::@method::~
  staticType: int
''');
  }

  test_tilde_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ~x;
}
''');

    var node = result.findNode.prefix('~x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: dart:core::@class::int::@method::~
  staticType: int
''');
  }
}
