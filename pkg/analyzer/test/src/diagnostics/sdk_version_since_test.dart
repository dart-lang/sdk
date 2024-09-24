// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionSinceTest);
  });
}

@reflectiveTest
class SdkVersionSinceTest extends SdkConstraintVerifierTest {
  @override
  List<MockSdkLibrary> additionalMockSdkLibraries = [];

  test_class_constructor_formalParameter_optionalNamed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  void A({@Since('2.15') int? foo});
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A(foo: 0);
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 3),
    ]);
  }

  test_class_constructor_formalParameter_optionalPositional() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  void A([@Since('2.15') int? foo]);
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A(42);
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 2),
    ]);
  }

  test_class_constructor_named_instanceCreation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A.named();
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A<int>.named();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 5),
    ]);
  }

  test_class_constructor_named_tearOff() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A.named();
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A<int>.named;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 5),
    ]);
  }

  test_class_constructor_unnamed_instanceCreation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A();
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A<int>();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 33, 1),
    ]);
  }

  test_class_field_read() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo;
  a.foo;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
      error(WarningCode.SDK_VERSION_SINCE, 49, 3),
    ]);
  }

  test_class_field_readWrite() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
  a.foo += 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
      error(WarningCode.SDK_VERSION_SINCE, 54, 3),
    ]);
  }

  test_class_field_write() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
  a.foo = 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
      error(WarningCode.SDK_VERSION_SINCE, 53, 3),
    ]);
  }

  test_class_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int get foo => 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo;
  a.foo;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
      error(WarningCode.SDK_VERSION_SINCE, 49, 3),
    ]);
  }

  test_class_getterSetter_readWrite_both() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int get foo => 0;
  @Since('2.15')
  set foo(int _) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a.foo += 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);
  }

  test_class_getterSetter_readWrite_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int get foo => 0;
  set foo(int _) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a.foo += 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);
  }

  test_class_getterSetter_readWrite_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  int get foo => 0;
  @Since('2.15')
  set foo(int _) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a.foo += 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);
  }

  test_class_indexRead() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int operator[](int index) => 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a[0];
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 37, 1),
    ]);
  }

  test_class_indexWrite() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  operator[]=(int index, int value) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a[0] = 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 37, 1),
    ]);
  }

  test_class_instanceCreation_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo' as foo;

void f() {
  foo.A<int>();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 44, 1),
    ]);
  }

  test_class_instanceCreation_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  A<int>();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 33, 1),
    ]);
  }

  test_class_method_call_functionExpressionInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void call() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 37, 2),
    ]);
  }

  test_class_method_formalParameter_optionalNamed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

void foo(
  int a, {
  @Since('2.15')
  int? bar,
}) {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  foo(0, bar: 1);
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
    ]);
  }

  test_class_method_formalParameter_optionalPositional() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

void foo(
  int a, [
  @Since('2.15')
  int? bar,
]) {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  foo(0, 42);
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 2),
    ]);
  }

  test_class_method_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a.foo();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);
  }

  test_class_method_methodTearOff_prefixedIdentifier() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  a.foo;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);

    var node = findNode.prefixed('.foo');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: dart:foo::<fragment>::@class::A::@method::foo
    element: dart:foo::<fragment>::@class::A::@method::foo#element
    staticType: void Function()
  staticElement: dart:foo::<fragment>::@class::A::@method::foo
  element: dart:foo::<fragment>::@class::A::@method::foo#element
  staticType: void Function()
''');
  }

  test_class_method_methodTearOff_propertyAccess() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
    ]);

    var node = findNode.propertyAccess('.foo');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: dart:foo::<fragment>::@class::A::@method::foo
    element: dart:foo::<fragment>::@class::A::@method::foo#element
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_class_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  set foo(int _) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
  a.foo = 0;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 40, 3),
      error(WarningCode.SDK_VERSION_SINCE, 53, 3),
    ]);
  }

  test_class_typeAnnotation_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo' as foo;

void f(foo.A<int> a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 1),
    ]);
  }

  test_class_typeAnnotation_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A<int> a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_constraints_exact_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('2.15.0', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_exact_greater() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('2.16.0', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_exact_less() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('2.14.0', '''
import 'dart:foo';

void f(A a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_constraints_greater_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('>2.15.0', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('>=2.15.0', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_equal_preRelease() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('>=2.15.0-pre', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_greater() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('>=2.16.0', '''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_less() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(A a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_enum_constant() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

enum E {
  v1,
  @Since('2.15')
  v2
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  E.v2;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 2),
    ]);
  }

  test_enum_index_onConcreteEnum() async {
    await verifyVersion('>=2.12.0', '''
enum E { v }

void f(E e) {
  e.index;
}
''');
  }

  test_enum_index_onDartCoreEnum() async {
    await verifyVersion('>=2.12.0', '''
void f(Enum e) {
  e.index;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 7, 4),
      error(WarningCode.SDK_VERSION_SINCE, 21, 5),
    ]);
  }

  test_enum_index_onDartCoreEnum_fromOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
Enum get myEnum => throw 0;
''');

    await verifyVersion('>=2.12.0', '''
import 'a.dart';

void f() {
  myEnum.index;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 5),
    ]);
  }

  test_enum_typeAnnotation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
enum E {
  v
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(E a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_extension_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  int get foo => 0;
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  0.foo;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 3),
    ]);
  }

  test_extension_itself_extensionOverride_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
extension E on int {
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  E(0).foo();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 38, 3),
    ]);
  }

  test_extension_itself_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
extension E on int {
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  0.foo();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 3),
    ]);
  }

  test_extension_method_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  void foo() {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  0.foo();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 3),
    ]);
  }

  test_extension_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  set foo(int _) {}
}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  0.foo = 1;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 35, 3),
    ]);
  }

  test_functionTypeAlias() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
typedef void X(int _);
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(X a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_genericTypeAlias() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
typedef X = List<int>;
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(X a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_mixin_typeAnnotation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
mixin M<T> {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f(M<int> a) {}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 27, 1),
    ]);
  }

  test_topLevelFunction_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
void bar() {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo' as foo;

void f() {
  foo.bar();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 44, 3),
    ]);
  }

  test_topLevelFunction_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
void foo() {}
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  foo();
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 33, 3),
    ]);
  }

  test_topLevelVariable_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
const v = 0;
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo' as foo;

void f() {
  foo.v;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 44, 1),
    ]);
  }

  test_topLevelVariable_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
const v = 0;
''');

    await verifyVersion('>=2.14.0', '''
import 'dart:foo';

void f() {
  v;
}
''', expectedErrors: [
      error(WarningCode.SDK_VERSION_SINCE, 33, 1),
    ]);
  }

  void _addDartFooLibrary(String content) {
    additionalMockSdkLibraries.add(
      MockSdkLibrary('foo', [
        MockSdkLibraryUnit('foo/foo.dart', content),
      ]),
    );
  }
}
