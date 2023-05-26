// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldPromotionTest);
  });
}

@reflectiveTest
class FieldPromotionTest extends PubPackageResolutionTest {
  test_class_field_invocation_prefixedIdentifier_nullability() async {
    await assertNoErrorsInCode('''
class C {
  final void Function()? _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo != null) {
    c._foo();
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_class_field_invocation_prefixedIdentifier_returnType() async {
    await assertNoErrorsInCode('''
class C {
  final int? Function() _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo is int Function()) {
    c._foo();
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_class_field_invocation_propertyAccess_nullability() async {
    await assertNoErrorsInCode('''
class C {
  final void Function()? _foo;
  C(this._foo);
}

void f(C c) {
  if ((c)._foo != null) {
    (c)._foo();
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::f::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_class_field_invocation_propertyAccess_returnType() async {
    await assertNoErrorsInCode('''
class C {
  final int? Function() _foo;
  C(this._foo);
}

void f(C c) {
  if ((c)._foo is int Function()) {
    (c)._foo();
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::f::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_class_field_invocation_simpleIdentifier_nullability() async {
    await assertNoErrorsInCode('''
class C {
  final void Function()? _foo;
  C(this._foo);
}

class D extends C {
  D(super.value);

  void f() {
    if (_foo != null) {
      _foo();
    }
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_class_field_invocation_simpleIdentifier_returnType() async {
    await assertNoErrorsInCode('''
class C {
  final int? Function() _foo;
  C(this._foo);
}

class D extends C {
  D(super.value);

  void f() {
    if (_foo is int Function()) {
      _foo();
    }
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_class_field_invocation_superPropertyAccess_nullability() async {
    await assertNoErrorsInCode('''
class C {
  final void Function()? _foo;
  C(this._foo);
}

class D extends C {
  D(super.value);

  void f() {
    if (super._foo != null) {
      super._foo();
    }
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: D
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_class_field_invocation_superPropertyAccess_returnType() async {
    await assertNoErrorsInCode('''
class C {
  final int? Function() _foo;
  C(this._foo);
}

class D extends C {
  D(super.value);

  void f() {
    if (super._foo is int Function()) {
      super._foo();
    }
  }
}
''');
    var node = findNode.functionExpressionInvocation('_foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: D
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: self::@class::C::@getter::_foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_class_field_notFinal() async {
    await assertNoErrorsInCode('''
class C {
  int? _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo != null) {
    c._foo;
  }
}
''');
    var node = findNode.prefixed('c._foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int?
  staticElement: self::@class::C::@getter::_foo
  staticType: int?
''');
  }

  test_class_field_notPrivate() async {
    await assertNoErrorsInCode('''
class C {
  int? foo;
  C(this.foo);
}

void f(C c) {
  if (c.foo != null) {
    c.foo;
  }
}
''');
    var node = findNode.prefixed('.foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: int?
  staticElement: self::@class::C::@getter::foo
  staticType: int?
''');
  }

  test_class_field_read_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class C {
  final int? _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo != null) {
    c._foo;
  }
}
''');
    var node = findNode.prefixed('c._foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int
  staticElement: self::@class::C::@getter::_foo
  staticType: int
''');
  }

  test_class_field_read_propertyAccess() async {
    await assertNoErrorsInCode('''
class C {
  final int? _foo;
  C(this._foo);
}

void f(C c) {
  if ((c)._foo != null) {
    (c)._foo;
  }
}
''');
    var node = findNode.propertyAccess('._foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    rightParenthesis: )
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int
  staticType: int
''');
  }

  test_class_field_read_propertyAccess_super() async {
    await assertNoErrorsInCode('''
class C {
  final int? _foo;
  C(this._foo);
}

class D extends C {
  D(super.value);

  void f() {
    if (super._foo != null) {
      super._foo;
    }
  }
}
''');
    var node = findNode.propertyAccess('._foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: D
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int
  staticType: int
''');
  }

  test_class_field_read_simpleIdentifier() async {
    await assertNoErrorsInCode('''
class C {
  final int? _foo;
  C(this._foo);

  void f() {
    if (_foo != null) {
      _foo; // read
    }
  }
}
''');
    var node = findNode.simple('_foo; // read');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _foo
  staticElement: self::@class::C::@getter::_foo
  staticType: int
''');
  }

  test_class_getter_read() async {
    await assertNoErrorsInCode('''
abstract class C {
  int? get _foo;
}

void f(C c) {
  if (c._foo != null) {
    c._foo;
  }
}
''');
    var node = findNode.prefixed('c._foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int?
  staticElement: self::@class::C::@getter::_foo
  staticType: int?
''');
  }

  test_classTypeAlias_construction() async {
    // In an earlier implementation attempt, field promotability was computed
    // prior to supertypes to class type aliases.  As a result, the class type
    // aliases' `supertype` fields were frozen at `null`, and consequently,
    // synthetic constructors weren't properly built for them, leading to bogus
    // error messages when constructing them.  This is a regression test to
    // ensure that mistake doesn't happen again.
    await assertNoErrorsInCode('''
mixin M {
  // ignore:unused_field
  int? _x = 43;
}

class C = Object with M;

void f() {
  C();
}
''');
  }

  test_enum_field() async {
    await assertNoErrorsInCode('''
enum E {
  v(null);
  final int? _foo;
  const E(this._foo);
}

void f(E e) {
  if (e._foo != null) {
    e._foo;
  }
}
''');
    var node = findNode.prefixed('._foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: e
    staticElement: self::@function::f::@parameter::e
    staticType: E
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: self::@enum::E::@getter::_foo
    staticType: int
  staticElement: self::@enum::E::@getter::_foo
  staticType: int
''');
  }

  test_language219() async {
    await assertNoErrorsInCode('''
// @dart = 2.19
class C {
  final int? _foo;
  C(this._foo);
}

void f(C c) {
  if ((c)._foo != null) {
    (c)._foo;
  }
}
''');
    var node = findNode.propertyAccess('._foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    rightParenthesis: )
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    staticElement: self::@class::C::@getter::_foo
    staticType: int?
  staticType: int?
''');
  }

  test_super_get() async {
    await assertNoErrorsInCode('''
class B {
  final int? _i;
  B(this._i);
}
class C extends B {
  final int? _i;
  C(this._i, int? superI) : super(superI);

  void f() {
    if (_i != null) { // A
      _i;
      super._i;
    }
    if (super._i != null) { // B
      _i;
      super._i;
    }
  }
}
''');
    var blockA = findNode.block('// A');
    assertResolvedNodeText(blockA, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: _i
        staticElement: self::@class::C::@getter::_i
        staticType: int
      semicolon: ;
    ExpressionStatement
      expression: PropertyAccess
        target: SuperExpression
          superKeyword: super
          staticType: C
        operator: .
        propertyName: SimpleIdentifier
          token: _i
          staticElement: self::@class::B::@getter::_i
          staticType: int?
        staticType: int?
      semicolon: ;
  rightBracket: }
''');
    var blockB = findNode.block('// B');
    assertResolvedNodeText(blockB, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: _i
        staticElement: self::@class::C::@getter::_i
        staticType: int?
      semicolon: ;
    ExpressionStatement
      expression: PropertyAccess
        target: SuperExpression
          superKeyword: super
          staticType: C
        operator: .
        propertyName: SimpleIdentifier
          token: _i
          staticElement: self::@class::B::@getter::_i
          staticType: int
        staticType: int
      semicolon: ;
  rightBracket: }
''');
  }

  test_super_get_inGenericClass() async {
    await assertNoErrorsInCode('''
class B<T extends Object> {
  final T? _t;
  B(this._t);
}
class C<T extends Object> extends B<T> {
  final T? _t;
  C(this._t, T? superT) : super(superT);

  void f() {
    if (_t != null) { // A
      _t;
      super._t;
    }
    if (super._t != null) { // B
      _t;
      super._t;
    }
  }
}
''');
    var blockA = findNode.block('// A');
    assertResolvedNodeText(blockA, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: _t
        staticElement: self::@class::C::@getter::_t
        staticType: T
      semicolon: ;
    ExpressionStatement
      expression: PropertyAccess
        target: SuperExpression
          superKeyword: super
          staticType: C<T>
        operator: .
        propertyName: SimpleIdentifier
          token: _t
          staticElement: PropertyAccessorMember
            base: self::@class::B::@getter::_t
            substitution: {T: T}
          staticType: T?
        staticType: T?
      semicolon: ;
  rightBracket: }
''');
    var blockB = findNode.block('// B');
    assertResolvedNodeText(blockB, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: _t
        staticElement: self::@class::C::@getter::_t
        staticType: T?
      semicolon: ;
    ExpressionStatement
      expression: PropertyAccess
        target: SuperExpression
          superKeyword: super
          staticType: C<T>
        operator: .
        propertyName: SimpleIdentifier
          token: _t
          staticElement: PropertyAccessorMember
            base: self::@class::B::@getter::_t
            substitution: {T: T}
          staticType: T
        staticType: T
      semicolon: ;
  rightBracket: }
''');
  }

  test_super_getAndInvoke() async {
    await assertNoErrorsInCode('''
class B {
  final int? Function() _f;
  B(this._f);
}
class C extends B {
  final int? Function() _f;
  C(this._f, int? Function() superF) : super(superF);

  void f() {
    if (_f is int Function()) { // A
      _f();
      super._f();
    }
    if (super._f is int Function()) { // B
      _f();
      super._f();
    }
  }
}
''');
    var blockA = findNode.block('// A');
    assertResolvedNodeText(blockA, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: _f
          staticElement: self::@class::C::@getter::_f
          staticType: int Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: int Function()
        staticType: int
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PropertyAccess
          target: SuperExpression
            superKeyword: super
            staticType: C
          operator: .
          propertyName: SimpleIdentifier
            token: _f
            staticElement: self::@class::B::@getter::_f
            staticType: int? Function()
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: int? Function()
        staticType: int?
      semicolon: ;
  rightBracket: }
''');
    var blockB = findNode.block('// B');
    assertResolvedNodeText(blockB, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: _f
          staticElement: self::@class::C::@getter::_f
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: int? Function()
        staticType: int?
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PropertyAccess
          target: SuperExpression
            superKeyword: super
            staticType: C
          operator: .
          propertyName: SimpleIdentifier
            token: _f
            staticElement: self::@class::B::@getter::_f
            staticType: int Function()
          staticType: int Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: int Function()
        staticType: int
      semicolon: ;
  rightBracket: }
''');
  }

  test_super_getAndInvoke_inGenericClass() async {
    await assertNoErrorsInCode('''
class B<T extends Object> {
  final T? Function() _f;
  B(this._f);
}
class C<T extends Object> extends B<T> {
  final T? Function() _f;
  C(this._f, T? Function() superF) : super(superF);

  void f() {
    if (_f is T Function()) { // A
      _f();
      super._f();
    }
    if (super._f is T Function()) { // B
      _f();
      super._f();
    }
  }
}
''');
    var blockA = findNode.block('// A');
    assertResolvedNodeText(blockA, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: _f
          staticElement: self::@class::C::@getter::_f
          staticType: T Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: T Function()
        staticType: T
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PropertyAccess
          target: SuperExpression
            superKeyword: super
            staticType: C<T>
          operator: .
          propertyName: SimpleIdentifier
            token: _f
            staticElement: PropertyAccessorMember
              base: self::@class::B::@getter::_f
              substitution: {T: T}
            staticType: T? Function()
          staticType: T? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: T? Function()
        staticType: T?
      semicolon: ;
  rightBracket: }
''');
    var blockB = findNode.block('// B');
    assertResolvedNodeText(blockB, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: _f
          staticElement: self::@class::C::@getter::_f
          staticType: T? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: T? Function()
        staticType: T?
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PropertyAccess
          target: SuperExpression
            superKeyword: super
            staticType: C<T>
          operator: .
          propertyName: SimpleIdentifier
            token: _f
            staticElement: PropertyAccessorMember
              base: self::@class::B::@getter::_f
              substitution: {T: T}
            staticType: T Function()
          staticType: T Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: T Function()
        staticType: T
      semicolon: ;
  rightBracket: }
''');
  }
}
