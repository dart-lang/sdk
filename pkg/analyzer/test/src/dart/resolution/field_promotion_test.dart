// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldPromotionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FieldPromotionTest extends PubPackageResolutionTest {
  test_cascaded_invocation() async {
    await assertNoErrorsInCode('''
class C {
  final Object? _field;
  C(this._field);
}
void f(C c) {
  c._field as int Function();
  c.._field().toString();
}
''');
    var node = findNode.functionExpressionInvocation('_field()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: _field
    staticElement: <testLibraryFragment>::@class::C::@getter::_field
    element: <testLibraryFragment>::@class::C::@getter::_field#element
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_cascaded_propertyAccess() async {
    await assertNoErrorsInCode('''
class C {
  final Object? _field;
  C(this._field);
}
void f(C c) {
  c._field as int;
  c.._field.toString();
}
''');
    var node = findNode.methodInvocation('_field.toString');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: _field
      staticElement: <testLibraryFragment>::@class::C::@getter::_field
      element: <testLibraryFragment>::@class::C::@getter::_field#element
      staticType: int
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::<fragment>::@class::int::@method::toString
    element: dart:core::<fragment>::@class::int::@method::toString#element
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_cascaded_propertyAccess_nullAware() async {
    await assertNoErrorsInCode('''
class C {
  final Object? _field;
  C(this._field);
}
void f(C? c) {
  c?.._field!.toString().._field.toString();
  c?._field;
}
''');
    // The `!` in the first statement promotes _field within the cascade
    assertResolvedNodeText(findNode.propertyAccess('_field.toString'), r'''
PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: _field
    staticElement: <testLibraryFragment>::@class::C::@getter::_field
    element: <testLibraryFragment>::@class::C::@getter::_field#element
    staticType: Object
  staticType: Object
''');
    // But the promotion doesn't last beyond the cascade expression, due to the
    // implicit control flow join when the `?..` stops taking effect.
    assertResolvedNodeText(findNode.propertyAccess('c?._field'), r'''
PropertyAccess
  target: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C?
  operator: ?.
  propertyName: SimpleIdentifier
    token: _field
    staticElement: <testLibraryFragment>::@class::C::@getter::_field
    element: <testLibraryFragment>::@class::C::@getter::_field#element
    staticType: Object?
  staticType: Object?
''');
  }

  test_class_field_abstract() async {
    // Even though an abstract non-final field is just syntactic sugar for an
    // abstract getter/setter pair (and thus in principle shouldn't prevent
    // promotion), there's no way to implement it without introducing either a
    // getter or a non-final field (either of which would prevent promotion). So
    // the implementation goes ahead and prevents promotion even if there's no
    // implementation yet, to reduce churn for the user.
    await assertNoErrorsInCode('''
abstract class B {
  abstract int? _foo;
}

// Suppress "unused field" warning on `B._foo`.
int? f(B b) => b._foo;

class C {
  final int? _foo;
  C(this._foo);
}

void g(C c) {
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::c
    element: <testLibraryFragment>::@function::g::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
  staticType: int?
''');
  }

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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@class::C::@getter::_foo
      element: <testLibraryFragment>::@class::C::@getter::_foo#element
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::foo
  element: <testLibraryFragment>::@class::C::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    rightParenthesis: )
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
  staticType: int
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::e
    element: <testLibraryFragment>::@function::f::@parameter::e#element
    staticType: E
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@enum::E::@getter::_foo
    element: <testLibraryFragment>::@enum::E::@getter::_foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@enum::E::@getter::_foo
  element: <testLibraryFragment>::@enum::E::@getter::_foo#element
  staticType: int
''');
  }

  test_extensionType_field_representation() async {
    await assertNoErrorsInCode('''
extension type A(int? _it) {}

void f(A a) {
  if (a._it != null) {
    a._it;
  }
}
''');
    var node = findNode.prefixed('a._it;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: _it
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::_it
    element: <testLibraryFragment>::@extensionType::A::@getter::_it#element
    staticType: int
  staticElement: <testLibraryFragment>::@extensionType::A::@getter::_it
  element: <testLibraryFragment>::@extensionType::A::@getter::_it#element
  staticType: int
''');
  }

  test_external_field() async {
    // External final fields should not be promotable.
    await assertNoErrorsInCode('''
class C {
  external final int? _field;
}
void f(C c) {
  c._field!;
  c._field;
}
''');
    var node = findNode.prefixed('c._field;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _field
    staticElement: <testLibraryFragment>::@class::C::@getter::_field
    element: <testLibraryFragment>::@class::C::@getter::_field#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::_field
  element: <testLibraryFragment>::@class::C::@getter::_field#element
  staticType: int?
''');
  }

  test_implemented_via_other_library() async {
    // When determining the set of fields/getters in a class's implementation,
    // it's necessary to traverse the whole class hierarchy, including classes
    // outside the current library, because a class outside the current library
    // may extend a class inside the current library. In the example below,
    // `c._foo` is promotable because class E doesn't contain any `noSuchMethod`
    // getters, due to the fact that it inherits an implementation of `_foo`
    // from `C` via `D`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

class D extends C {
  D(super.foo);
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';

class C {
  final int? _foo;
  C(this._foo);
}
class E extends D implements C {
  E(super.foo);
  noSuchMethod(_) => 12345;
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
  staticType: int
''');
  }

  test_interface_via_other_library() async {
    // When determining the set of fields/getters in a class's interface, it's
    // necessary to traverse the whole class hierarchy, including classes
    // outside the current library, because a class outside the current library
    // may extend or implement a class inside the current library. In the
    // example below, `c._foo` is not promotable because class E contains a
    // `noSuchMethod` getter for `_foo`, due to the fact that its interface
    // inherits `_foo` from `C` via `D`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

class D extends C {
  D(super.foo);
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';

class C {
  final int? _foo;
  C(this._foo);
}
class E implements D {
  noSuchMethod(_) => 12345;
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
  staticType: int?
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    rightParenthesis: )
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int?
  staticType: int?
''');
  }

  test_mixin_on_clause() async {
    // The type mentioned in a a mixin's "on" clause contributes to its
    // interface. This needs to be accounted for when determining whether a
    // `noSuchMethod` getter will be synthesized.  In the example below,
    // `c._foo` is not promotable because class D contains a `noSuchMethod`
    // getter for `_foo`.
    await assertNoErrorsInCode('''
mixin M on C {}
class C {
  final int? _foo;
  C(this._foo);
}
class D implements M {
  noSuchMethod(_) => 12345;
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    staticElement: <testLibraryFragment>::@class::C::@getter::_foo
    element: <testLibraryFragment>::@class::C::@getter::_foo#element
    staticType: int?
  staticElement: <testLibraryFragment>::@class::C::@getter::_foo
  element: <testLibraryFragment>::@class::C::@getter::_foo#element
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
        staticElement: <testLibraryFragment>::@class::C::@getter::_i
        element: <testLibraryFragment>::@class::C::@getter::_i#element
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
          staticElement: <testLibraryFragment>::@class::B::@getter::_i
          element: <testLibraryFragment>::@class::B::@getter::_i#element
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
        staticElement: <testLibraryFragment>::@class::C::@getter::_i
        element: <testLibraryFragment>::@class::C::@getter::_i#element
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
          staticElement: <testLibraryFragment>::@class::B::@getter::_i
          element: <testLibraryFragment>::@class::B::@getter::_i#element
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
        staticElement: <testLibraryFragment>::@class::C::@getter::_t
        element: <testLibraryFragment>::@class::C::@getter::_t#element
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
          staticElement: GetterMember
            base: <testLibraryFragment>::@class::B::@getter::_t
            substitution: {T: T}
          element: <testLibraryFragment>::@class::B::@getter::_t#element
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
        staticElement: <testLibraryFragment>::@class::C::@getter::_t
        element: <testLibraryFragment>::@class::C::@getter::_t#element
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
          staticElement: GetterMember
            base: <testLibraryFragment>::@class::B::@getter::_t
            substitution: {T: T}
          element: <testLibraryFragment>::@class::B::@getter::_t#element
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
          staticElement: <testLibraryFragment>::@class::C::@getter::_f
          element: <testLibraryFragment>::@class::C::@getter::_f#element
          staticType: int Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
            staticElement: <testLibraryFragment>::@class::B::@getter::_f
            element: <testLibraryFragment>::@class::B::@getter::_f#element
            staticType: int? Function()
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
          staticElement: <testLibraryFragment>::@class::C::@getter::_f
          element: <testLibraryFragment>::@class::C::@getter::_f#element
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
            staticElement: <testLibraryFragment>::@class::B::@getter::_f
            element: <testLibraryFragment>::@class::B::@getter::_f#element
            staticType: int Function()
          staticType: int Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
          staticElement: <testLibraryFragment>::@class::C::@getter::_f
          element: <testLibraryFragment>::@class::C::@getter::_f#element
          staticType: T Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
            staticElement: GetterMember
              base: <testLibraryFragment>::@class::B::@getter::_f
              substitution: {T: T}
            element: <testLibraryFragment>::@class::B::@getter::_f#element
            staticType: T? Function()
          staticType: T? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
          staticElement: <testLibraryFragment>::@class::C::@getter::_f
          element: <testLibraryFragment>::@class::C::@getter::_f#element
          staticType: T? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
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
            staticElement: GetterMember
              base: <testLibraryFragment>::@class::B::@getter::_f
              substitution: {T: T}
            element: <testLibraryFragment>::@class::B::@getter::_f#element
            staticType: T Function()
          staticType: T Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        element: <null>
        staticInvokeType: T Function()
        staticType: T
      semicolon: ;
  rightBracket: }
''');
  }
}
