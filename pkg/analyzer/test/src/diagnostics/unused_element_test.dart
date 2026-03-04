// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedElementTest);
  });
}

@reflectiveTest
class UnusedElementTest extends PubPackageResolutionTest {
  test_class_field_isUsed_objectPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case A(_foo: var bar)) {
    bar;
  }
}

class A {
  int _foo = 0;
}
''');
  }

  test_class_field_isUsed_objectPattern_generic() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case A<int>(_foo: var bar)) {
    bar;
  }
}

abstract class A<T> {
  abstract T _foo;
}
''');
  }

  test_class_getter_isUsed_objectPattern_hasName() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case A(_foo: var bar)) {
    bar;
  }
}

class A {
  int get _foo => 0;
}
''');
  }

  test_class_getter_isUsed_objectPattern_hasName_generic() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case A<int>(_foo: var bar)) {
    bar;
  }
}

class A<T> {
  T get _foo => throw 0;
}
''');
  }

  test_class_getterSetter_isUsed_assignmentExpression_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get _foo => 0;
  set _foo(int _) {}

  void f() {
    _foo += 2;
  }
}
''');
  }

  test_class_isUsed_exposedViaTypeAlias() async {
    await assertNoErrorsInCode(r'''
class _A {}
typedef T = _A;
''');
  }

  test_class_isUsed_extends() async {
    await assertNoErrorsInCode(r'''
class _A {}
class B extends _A {}
''');
  }

  test_class_isUsed_fieldDeclaration() async {
    await assertNoErrorsInCode(r'''
class Foo {
  _Bar? x;
}

class _Bar {
}
''');
  }

  test_class_isUsed_implements() async {
    await assertNoErrorsInCode(r'''
class _A {}
class B implements _A {}
''');
  }

  test_class_isUsed_instanceCreation() async {
    await assertNoErrorsInCode(r'''
class _A {}
main() {
  new _A();
}
''');
  }

  test_class_isUsed_isExpression_expression() async {
    await assertNoErrorsInCode('''
class _A {}
void f(Object p) {
  if (_A() is int) {
  }
}
''');
  }

  test_class_isUsed_jsAnnotation() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'js', rootPath: '$workspaceRootPath/js'),
    );

    newFile('$workspaceRootPath/js/lib/js.dart', r'''
library _js_annotations;

class JS {
  const JS();
}
''');

    await assertNoErrorsInCode(r'''
import 'package:js/js.dart';

@JS()
class _A {}
''');
  }

  test_class_isUsed_native() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class _A extends Struct {
  @Int32() external int x;
}

final List<_A> x = [];
''');
  }

  test_class_isUsed_staticFieldAccess() async {
    await assertNoErrorsInCode(r'''
class _A {
  static const F = 42;
}
main() {
  _A.F;
}
''');
  }

  test_class_isUsed_staticMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  static m() {}
}
main() {
  _A.m();
}
''');
  }

  test_class_isUsed_typeArgument() async {
    await assertNoErrorsInCode(r'''
class _A {}
main() {
  var v = new List<_A>.empty();
  print(v);
}
''');
  }

  test_class_isUsed_variableDeclaration() async {
    await assertNoErrorsInCode('''
class _A {}
void f() {
  // ignore: unused_local_variable
  _A? v;
}
''');
  }

  test_class_isUsed_variableDeclaration_typeArgument() async {
    await assertNoErrorsInCode('''
class _A {}
void f() {
  // ignore: unused_local_variable
  List<_A>? v;
}
''');
  }

  test_class_isUsed_with() async {
    await assertNoErrorsInCode(r'''
mixin class _A {}
class B with _A {}
''');
  }

  test_class_notUsed_inClassMember() async {
    await assertErrorsInCode(
      r'''
class _A {
  static staticMethod() {
    new _A();
  }
  instanceMethod() {
    new _A();
  }
}
''',
      [error(diag.unusedElement, 6, 2), error(diag.unusedElement, 20, 12)],
    );
  }

  test_class_notUsed_inConstructorName() async {
    await assertErrorsInCode(
      r'''
class _A {
  _A() {}
  _A.named() {}
}
''',
      [error(diag.unusedElement, 6, 2), error(diag.unusedElement, 26, 5)],
    );
  }

  test_class_notUsed_isExpression() async {
    await assertErrorsInCode(
      r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_class_notUsed_isExpression_typeArgument() async {
    await assertErrorsInCode(
      r'''
class _A {}
void f(Object p) {
  if (p is List<_A>) {
  }
}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_class_notUsed_isExpression_typeInFunctionType() async {
    await assertErrorsInCode(
      r'''
class _A {}
void f(Object p) {
  if (p is void Function(_A)) {
  }
}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_class_notUsed_isExpression_typeInTypeParameter() async {
    await assertErrorsInCode(
      r'''
class _A {}
void f(Object p) {
  if (p is void Function<T extends _A>()) {
  }
}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_class_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
class _A {}
main() {
}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_class_setter_isUsed_assignmentExpression_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set _foo(int _) {}

  void f() {
    _foo = 0;
  }
}
''');
  }

  test_constructor_isUsed_asRedirectee() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
  factory A.b() = A._constructor;
}
''');
  }

  test_constructor_isUsed_asRedirectee_viaInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
  A() : this._constructor();
}
''');
  }

  test_constructor_isUsed_asRedirectee_viaSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}

class B extends A {
  B() : super._constructor();
}
''');
  }

  test_constructor_isUsed_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}
A f() => A._constructor();
''');
  }

  test_constructor_notUsed_multiple() async {
    await assertErrorsInCode(
      r'''
class A {
  A._constructor();
  A();
}
''',
      [error(diag.unusedElement, 14, 12)],
    );
  }

  test_constructor_notUsed_multiple_primary() async {
    // A primary constructor can be used to declare fields.
    await assertNoErrorsInCode(r'''
class A._constructor(final int i) {
  factory A() => A._constructor(7);
}
''');
  }

  test_constructor_notUsed_multiple_withPrimary() async {
    await assertErrorsInCode(
      r'''
class A(final int i) {
  factory A._constructor() => A(7);
}
''',
      [error(diag.unusedElement, 35, 12)],
    );
  }

  test_constructor_notUsed_single() async {
    // We allow a single unused constructor which is used to prevent
    // instantiation and extending. We could instead report this and
    // recommend to use `interface class`.
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}
''');
  }

  test_constructor_notUsed_single_inSubclass() async {
    await assertErrorsInCode(
      r'''
class A {
  A._constructor();
}

class B extends A {
  B() : super._constructor();
  B._named() : super._constructor();
}
''',
      [error(diag.unusedElement, 87, 6)],
    );
  }

  test_constructor_notUsed_single_primary() async {
    // A primary constructor can be used to declare fields.
    await assertNoErrorsInCode(r'''
class A._constructor(final int i);
''');
  }

  test_constructorFactory_notUsed_multiple() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A._factory() => A();
  A();
}
''',
      [error(diag.unusedElement, 22, 8)],
    );
  }

  test_constructorFactory_notUsed_single() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A._factory() => throw 0;
}
''');
  }

  test_constructorPublic_privateClass_exposedViaTypeAlias() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A.constructor();
}
typedef T = _A;
''');
  }

  test_constructorPublic_privateClass_notUsed() async {
    await assertErrorsInCode(
      r'''
class _A {
  _A.named();
  _A();
}
var a = _A();
''',
      [error(diag.unusedElement, 16, 5)],
    );
  }

  test_dotShorthand_parameter_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A([this.f]);
}
void main() {
  _A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_fieldFormal_factory() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A([this.f]);
  factory _A.named([int? a]) = _A;
}
void main() {
  _A a;
  a = .named(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_generic() async {
    await assertNoErrorsInCode(r'''
class _A<T> {
  _A(T a);
}
void main() {
  _A<int> a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_named() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A({int a = 0});
}
void main() {
  _A a;
  a = .new(a: 0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_optional() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A([int a = 0]);
}
void main() {
  _A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_positional() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A(int a);
}
void main() {
  _A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int a = 0]);
}
void main() {
  A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_factory() async {
    await assertNoErrorsInCode(r'''
class A {
  final int? f;
  A([this.f]);
  factory A.named([int? a]) = A;
}
void main() {
  A a;
  a = .named(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final int? f;
  A([this.f]);
}
void main() {
  A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T a);
}
void main() {
  A<int> a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int a = 0});
}
void main() {
  A a;
  a = .new(a: 0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_optional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int a = 0]);
}
void main() {
  A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_parameter_public_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}
void main() {
  A a;
  a = .new(0);
  print(a);
}
''');
  }

  test_dotShorthand_private_constConstructorInvocation() async {
    await assertNoErrorsInCode(r'''
class _C {
  const _C.named();
}

void main() {
  _C c;
  c = const .named();
  print(c);
}
''');
  }

  test_dotShorthand_private_constConstructorInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class _C {
  const _C.named({int? p});
}
void main() {
  _C c;
  c = const .named(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_private_constructorInvocation() async {
    await assertNoErrorsInCode(r'''
class _C {}

void main() {
  _C c;
  c = .new();
  print(c);
}
''');
  }

  test_dotShorthand_private_constructorInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class _C {
  _C.named({int? p});
}
void main() {
  _C c;
  c = .named(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_private_enum() async {
    await assertNoErrorsInCode(r'''
enum _E { v }

void main() {
  _E e;
  e = .v;
  print(e);
}
''');
  }

  test_dotShorthand_private_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type _E(int i) {}

void main() {
  _E e;
  e = .new(0);
  print(e);
}
''');
  }

  test_dotShorthand_private_methodInvocation() async {
    await assertNoErrorsInCode(r'''
class _C {
  static _C foo() => _C();
}

void main() {
  _C c;
  c = .foo();
  print(c);
}
''');
  }

  test_dotShorthand_private_methodInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class _C {
  static _C foo({int? p}) => _C();
}
void main() {
  _C c;
  c = .foo(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_private_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class _C {
  static _C a = _C();
}

void main() {
  _C c;
  c = .a;
  print(c);
}
''');
  }

  test_dotShorthand_public_constConstructorInvocation() async {
    await assertNoErrorsInCode(r'''
class C {
  const C.named();
}

void main() {
  C c;
  c = const .named();
  print(c);
}
''');
  }

  test_dotShorthand_public_constConstructorInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class C {
  const C.named({int? p});
}
void main() {
  C c;
  c = const .named(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_public_constructorInvocation() async {
    await assertNoErrorsInCode(r'''
class C {}

void main() {
  C c;
  c = .new();
  print(c);
}
''');
  }

  test_dotShorthand_public_constructorInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class C {
  C.named({int? p});
}
void main() {
  C c;
  c = .named(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_public_enum() async {
    await assertNoErrorsInCode(r'''
enum E { v }

void main() {
  E e;
  e = .v;
  print(e);
}
''');
  }

  test_dotShorthand_public_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {}

void main() {
  E e;
  e = .new(0);
  print(e);
}
''');
  }

  test_dotShorthand_public_methodInvocation() async {
    await assertNoErrorsInCode(r'''
class C {
  static C foo() => C();
}

void main() {
  C c;
  c = .foo();
  print(c);
}
''');
  }

  test_dotShorthand_public_methodInvocation_argument() async {
    await assertNoErrorsInCode(r'''
class C {
  static C foo({int? p}) => C();
}
void main() {
  C c;
  c = .foo(p: 0);
  print(c);
}
''');
  }

  test_dotShorthand_public_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class C {
  static C a = C();
}

void main() {
  C c;
  c = .a;
  print(c);
}
''');
  }

  test_enum_constructor_parameter_optionalNamed_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(a: 0);
  const E({int? a});
}
''');
  }

  test_enum_constructor_parameter_optionalNamed_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v1, v2();
  const E({int? a});
}
''',
      [error(diag.unusedElementParameter, 37, 1)],
    );
  }

  test_enum_constructor_parameter_optionalPositional_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  const E([int? a]);
}
''');
  }

  test_enum_constructor_parameter_optionalPositional_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v1, v2();
  const E([int? a]);
}
''',
      [error(diag.unusedElementParameter, 37, 1)],
    );
  }

  test_enum_isUsed_fieldReference() async {
    await assertNoErrorsInCode(r'''
enum _MyEnum {A}
main() {
  _MyEnum.A;
}
''');
  }

  test_enum_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
enum _MyEnum {A, B}
void f(d) {
  d.A;
  d.B;
}
''',
      [error(diag.unusedElement, 5, 7)],
    );
  }

  test_extension_unnamed_getter_isUsed_objectPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int(foo: var bar)) {
    bar;
  }
}

extension on int {
  int get foo => 0;
}
''');
  }

  test_extension_unnamed_getter_isUsed_objectPattern_generic() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case List<int>(foo: var bar)) {
    bar;
  }
}

extension<T> on List<T> {
  T get foo => throw 0;
}
''');
  }

  test_extension_unnamed_operator_isUsed_relationalPattern() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  if (x case > 0) {}
}

extension on int? {
  bool operator >(int other) => true;
}
''');
  }

  test_extensionType_isUsed_typeName_typeArgument() async {
    await assertNoErrorsInCode(r'''
extension type _E(int i) {}

void f() {
  Map<_E, int>();
}
''');
  }

  test_extensionType_isUsed_variableDeclaration() async {
    await assertNoErrorsInCode('''
extension type _E(int i) {}

void f() {
  _E? v;
  print(v);
}
''');
  }

  test_extensionType_isUsed_variableDeclaration_typeArgument() async {
    await assertNoErrorsInCode('''
extension type _E(int i) {}

void f() {
  // ignore: unused_local_variable
  List<_E>? v;
}
''');
  }

  test_extensionType_member_notUsed() async {
    await assertErrorsInCode(
      '''
extension type E(int i) {
  void _f() {}
}
''',
      [error(diag.unusedElement, 33, 2)],
    );
  }

  test_extensionType_notUsed() async {
    await assertErrorsInCode(
      r'''
extension type _E(int i) {}
''',
      [error(diag.unusedElement, 15, 2)],
    );
  }

  test_extensionType_privateConstructor() async {
    await assertErrorsInCode(
      '''
extension type E(int i) {
  E._named(this.i);
}
''',
      [error(diag.unusedElement, 30, 6)],
    );
  }

  test_extensionType_privateConstructor_notExposedViaTypeAlias() async {
    await assertErrorsInCode(
      '''
extension type E(int i) {
  E._named(this.i);
}
typedef A = E;
''',
      [error(diag.unusedElement, 30, 6)],
    );
  }

  test_extensionTypePrivate_publicConstructor() async {
    await assertErrorsInCode(
      '''
extension type _E(int i) {
  _E.named(this.i);
}
''',
      [error(diag.unusedElement, 32, 5)],
    );
  }

  test_extensionTypePrivate_publicConstructor_exposedViaTypeAlias() async {
    await assertNoErrorsInCode('''
extension type _E(int i) {
  _E.named(this.i);
}
typedef A = _E;
''');
  }

  test_extensionTypePrivate_publicConstructor_exposedViaTypeAlias_indirect() async {
    await assertNoErrorsInCode('''
extension type _E(int i) {
  _E.named(this.i);
}
typedef _A = _E;
typedef B = _A;
''');
  }

  test_fieldImplicitGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
class A {
  int? _g;
  int? get g => this._g;
}
''');
  }

  test_function_underscore() async {
    await assertErrorsInCode(
      r'''
_(){}
''',
      [error(diag.unusedElement, 0, 1)],
    );
  }

  test_function_underscores() async {
    await assertErrorsInCode(
      r'''
__(){}
''',
      [error(diag.unusedElement, 0, 2)],
    );
  }

  test_functionLocal_isUsed_closure() async {
    await assertNoErrorsInCode(r'''
main() {
  print(() {});
}
print(x) {}
''');
  }

  test_functionLocal_isUsed_invocation() async {
    await assertNoErrorsInCode(r'''
main() {
  f() {}
  f();
}
''');
  }

  test_functionLocal_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
main() {
  f() {}
  print(f);
}
print(x) {}
''');
  }

  test_functionLocal_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
main() {
  f() {}
}
''',
      [error(diag.unusedElement, 11, 1)],
    );
  }

  test_functionLocal_notUsed_referenceFromItself() async {
    await assertErrorsInCode(
      r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}
''',
      [error(diag.unusedElement, 11, 2)],
    );
  }

  test_functionTypeAlias_isUsed_isExpression() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
main(f) {
  if (f is _F) {
    print('F');
  }
}
''');
  }

  test_functionTypeAlias_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
void f(_F c) {
}
''');
  }

  test_functionTypeAlias_isUsed_typeArgument() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
main() {
  var v = new List<_F>.empty();
  print(v);
}
''');
  }

  test_functionTypeAlias_isUsed_variableDeclaration() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
class A {
  _F? f;
}
''');
  }

  test_functionTypeAlias_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
typedef _F(a, b);
main() {
}
''',
      [error(diag.unusedElement, 8, 2)],
    );
  }

  test_getter_isUsed_invocation_deepSubclass() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String get _debugName;

  String toString() {
    return _debugName;
  }
}

class B extends A {
  @override
  String get _debugName => "B";
}

class C extends B {
  String get _debugName => "C";
}
''');
  }

  test_getter_isUsed_invocation_implicitThis() async {
    await assertErrorsInCode(
      r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}
''',
      [error(diag.unusedLocalVariable, 52, 1)],
    );
  }

  test_getter_isUsed_invocation_parameterized() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  List<int> _list = List.filled(1, 1);
  int get _item => _list.first;
  set _item(int item) => _list[0] = item;
}
class B<T> {
  A<T> a = A<T>();
}
void main() {
  B<int> b = B();
  b.a._item = 3;
  print(b.a._item == 7);
}
''');
  }

  test_getter_isUsed_invocation_parameterized_subclass() async {
    await assertNoErrorsInCode(r'''
abstract class A<T> {
  T get _defaultThing;
  T? _thing;

  void main() {
    _thing ??= _defaultThing;
    print(_thing);
  }
}
class B extends A<int> {
  @override
  int get _defaultThing => 7;
}
''');
  }

  test_getter_isUsed_invocation_prefixedIdentifier() async {
    await assertErrorsInCode(
      r'''
class A {
  get _g => null;
}
void f(A a) {
  var v = a._g;
}
''',
      [error(diag.unusedLocalVariable, 50, 1)],
    );
  }

  test_getter_isUsed_invocation_propertyAccess() async {
    await assertErrorsInCode(
      r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''',
      [error(diag.unusedLocalVariable, 45, 1)],
    );
  }

  test_getter_isUsed_invocation_subclass_plusPlus() async {
    await assertNoErrorsInCode(r'''
class A {
  int __a = 0;
  int get _a => __a;
  void set _a(int val) {
    __a = val;
  }
  int b() => _a++;
}
class B extends A {
  @override
  int get _a => 3;
}
''');
  }

  test_getter_notUsed_invocation_subclass() async {
    await assertErrorsInCode(
      r'''
class A {
  int __a = 0;
  int get _a => __a;
  void set _a(int val) {
    __a = val;
  }
  int b() => _a = 7;
}
class B extends A {
  @override
  int get _a => 3;
}
''',
      [error(diag.unusedElement, 35, 2), error(diag.unusedElement, 155, 2)],
    );
  }

  test_getter_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
class A {
  get _g => null;
}
''',
      [error(diag.unusedElement, 16, 2)],
    );
  }

  test_getter_notUsed_referenceFromItself() async {
    await assertErrorsInCode(
      r'''
class A {
  get _g {
    return _g;
  }
}
''',
      [error(diag.unusedElement, 16, 2)],
    );
  }

  test_localFunction_inFunction_wildcard() async {
    await assertErrorsInCode(
      r'''
m() {
  _(){}
}
''',
      [
        // Code is dead but not unused.
        error(diag.deadCode, 8, 5),
      ],
    );
  }

  test_localFunction_inFunction_wildcard_preWildCards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

main() {
  _(){}
}
''',
      [error(diag.unusedElement, 55, 1)],
    );
  }

  test_localFunction_inMethod_underscores() async {
    await assertErrorsInCode(
      r'''
class C {
  m() {
    __(){}
  }
}
''',
      [error(diag.unusedElement, 22, 2)],
    );
  }

  test_localFunction_inMethod_wildcard() async {
    await assertErrorsInCode(
      r'''
class C {
  m() {
    _(){}
  }
}
''',
      [
        // Code is dead but not unused.
        error(diag.deadCode, 22, 5),
      ],
    );
  }

  test_localFunction_inMethod_wildcard_preWildCards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  m() {
    _(){}
  }
}
''',
      [error(diag.unusedElement, 66, 1)],
    );
  }

  test_localFunction_underscores() async {
    await assertErrorsInCode(
      r'''
main() {
  __(){}
}
''',
      [error(diag.unusedElement, 11, 2)],
    );
  }

  test_method_isUsed_call_inExtension() async {
    await assertNoErrorsInCode(r'''
extension<T> on T {
  void call() {}
}

void f() {
  (<T>(T t) => t())(7);
}
''');
  }

  test_method_isUsed_hasPragma_vmEntryPoint() async {
    pragma;
    await assertNoErrorsInCode(r'''
class A {
  @pragma('vm:entry-point')
  void _foo() {}
}
''');
  }

  test_method_isUsed_hasReference_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
print(x) {}
''');
  }

  test_method_isUsed_hasReference_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
class B extends A {
  _m() {}
}
print(x) {}
''');
  }

  test_method_isUsed_hasReference_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
void f(A a) {
  a._m;
}
''');
  }

  test_method_isUsed_hasReference_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  new A()._m;
}
''');
  }

  test_method_isUsed_invocation_fromMixinApplication() async {
    await assertNoErrorsInCode(r'''
mixin A {
  _m() {}
}
class C with A {
  useMethod() {
    _m();
  }
}
''');
  }

  test_method_isUsed_invocation_fromMixinWithConstraint() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
mixin M on A {
  useMethod() {
    _m();
  }
}
''');
  }

  test_method_isUsed_invocation_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
''');
  }

  test_method_isUsed_invocation_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
class B extends A {
  _m() {}
}
''');
  }

  test_method_isUsed_invocation_memberElement() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  _m(T t) {}
}
void f(A<int> a) {
  a._m(0);
}
''');
  }

  test_method_isUsed_invocation_propagated() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  var a = new A();
  a._m();
}
''');
  }

  test_method_isUsed_invocation_static() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  A a = new A();
  a._m();
}
''');
  }

  test_method_isUsed_invocation_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
class B extends A {
  _m() {}
}
void f(A a) {
  a._m();
}
''');
  }

  test_method_isUsed_privateExtension() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  void m() {}
}
void main() {
  "hello".m();
}
''');
  }

  test_method_isUsed_privateExtension_binaryOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  int operator -(int other) => other;
}
void main() {
  "hello" - 3;
}
''');
  }

  test_method_isUsed_privateExtension_generic_binaryOperator() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  int operator -(int other) => other;
}
void f(A<int> a) {
  a - 3;
}
''');
  }

  test_method_isUsed_privateExtension_generic_indexEqOperator() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  void operator []=(int index, T value) {
}}
void f(A<int> a) {
  a[0] = 1;
}
''');
  }

  test_method_isUsed_privateExtension_generic_indexOperator() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  A<T> operator [](int index) => throw 0;
}
void f(A<int> a) {
  a[0];
}
''');
  }

  test_method_isUsed_privateExtension_generic_method() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  A<T> foo() => throw 0;
}
void f(A<int> a) {
  a.foo();
}
''');
  }

  test_method_isUsed_privateExtension_generic_postfixOperator() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  A<T> operator -(int i) => throw 0;
}
void f(A<int> a) {
  a--;
}
''');
  }

  test_method_isUsed_privateExtension_generic_prefixOperator() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
extension _A<T> on A<T> {
  T operator ~() => throw 0;
}
void f(A<int> a) {
  ~a;
}
''');
  }

  test_method_isUsed_privateExtension_indexEqOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on bool {
  operator []=(int index, int value) {}
}
void main() {
  false[0] = 1;
}
''');
  }

  test_method_isUsed_privateExtension_indexOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on bool {
  int operator [](int index) => 7;
}
void main() {
  false[3];
}
''');
  }

  test_method_isUsed_privateExtension_methodCall() async {
    await assertNoErrorsInCode(r'''
extension _E on int {
  void call() {}
}

void f() {
  0();
}
''');
  }

  test_method_isUsed_privateExtension_operator_assignment() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  String operator -(int other) => this;
}
void f(String s) {
  s -= 3;
}
''');
  }

  test_method_isUsed_privateExtension_postfixOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  String operator -(int i) => this;
}
void f(String a) {
  a--;
}
''');
  }

  test_method_isUsed_privateExtension_prefixOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  int operator ~() => 7;
}
void main() {
  ~"hello";
}
''');
  }

  test_method_isUsed_public() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
main() {
}
''');
  }

  test_method_isUsed_staticInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  static _m() {}
}
main() {
  A._m();
}
''');
  }

  test_method_isUsed_unnamedExtension() async {
    await assertNoErrorsInCode(r'''
extension on String {
  void m() {}
}
void main() {
  "hello".m();
}
''');
  }

  test_method_isUsed_unnamedExtension_methodCall() async {
    await assertNoErrorsInCode(r'''
extension on int {
  void call() {}
}

void f() {
  0();
}
''');
  }

  test_method_isUsed_unnamedExtension_operator() async {
    await assertNoErrorsInCode(r'''
extension on String {
  int operator -(int other) => other;
}
void main() {
  "hello" - 3;
}
''');
  }

  test_method_notUsed_call_inExtension() async {
    await assertErrorsInCode(
      r'''
extension<T> on T {
  void call() {}
}
''',
      [error(diag.unusedElement, 27, 4)],
    );
  }

  test_method_notUsed_hasSameNameAsUsed() async {
    await assertErrorsInCode(
      r'''
class A {
  void _m1() {}
}
class B {
  void public() => _m1();
  void _m1() {}
}
''',
      [error(diag.unusedElement, 17, 3)],
    );
  }

  test_method_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
class A {
  static _m() {}
}
''',
      [error(diag.unusedElement, 19, 2)],
    );
  }

  test_method_notUsed_privateExtension() async {
    await assertErrorsInCode(
      r'''
extension _A on String {
  void m() {}
}
''',
      [error(diag.unusedElement, 32, 1)],
    );
  }

  /// Postfix operators can only be called, not defined. The "notUsed" sibling to
  /// this test is the test on a binary operator.
  test_method_notUsed_privateExtension_indexEqOperator() async {
    await assertErrorsInCode(
      r'''
extension _A on bool {
  operator []=(int index, int value) {}
}
''',
      [error(diag.unusedElement, 34, 3)],
    );
  }

  test_method_notUsed_privateExtension_indexOperator() async {
    await assertErrorsInCode(
      r'''
extension _A on bool {
  int operator [](int index) => 7;
}
''',
      [error(diag.unusedElement, 38, 2)],
    );
  }

  test_method_notUsed_privateExtension_methodCall() async {
    await assertErrorsInCode(
      r'''
extension _E on int {
  void call() {}
}
''',
      [error(diag.unusedElement, 29, 4)],
    );
  }

  /// Assignment operators can only be called, not defined. The "notUsed" sibling
  /// to this test is the test on a binary operator.
  test_method_notUsed_privateExtension_operator() async {
    await assertErrorsInCode(
      r'''
extension _A on String {
  int operator -(int other) => other;
}
''',
      [error(diag.unusedElement, 40, 1)],
    );
  }

  test_method_notUsed_privateExtension_prefixOperator() async {
    await assertErrorsInCode(
      r'''
extension _A on String {
  int operator ~() => 7;
}
''',
      [error(diag.unusedElement, 40, 1)],
    );
  }

  test_method_notUsed_referenceFromItself() async {
    await assertErrorsInCode(
      r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}
''',
      [error(diag.unusedElement, 19, 2)],
    );
  }

  test_method_notUsed_referenceInComment() async {
    await assertErrorsInCode(
      r'''
/// [A] has a method, [_f].
class A {
  int _f(int p) => 7;
}
''',
      [error(diag.unusedElement, 44, 2)],
    );
  }

  test_method_notUsed_referenceInComment_outsideEnclosingClass() async {
    await assertErrorsInCode(
      r'''
class A {
  int _f(int p) => 7;
}
/// This is similar to [A._f].
int g() => 7;
''',
      [error(diag.unusedElement, 16, 2)],
    );
  }

  test_method_notUsed_unnamedExtension() async {
    await assertErrorsInCode(
      r'''
extension on String {
  void m() {}
}
''',
      [error(diag.unusedElement, 29, 1)],
    );
  }

  test_method_notUsed_unnamedExtension_operator() async {
    await assertErrorsInCode(
      r'''
extension on String {
  int operator -(int other) => other;
}
''',
      [error(diag.unusedElement, 37, 1)],
    );
  }

  test_mixin_isUsed_with() async {
    await assertNoErrorsInCode(r'''
mixin _M {}
class C with _M {}
''');
  }

  test_mixin_notUsed() async {
    await assertErrorsInCode(
      r'''
mixin _M {}
''',
      [error(diag.unusedElement, 6, 2)],
    );
  }

  test_parameter_isUsed_constructor() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A([int a = 0]);
}
f() => _A(0);
''');
  }

  test_parameter_isUsed_fieldFormal_constructorInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A([this.f]);
}
f() => _A(0);
''');
  }

  test_parameter_isUsed_fieldFormal_factoryRedirect() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A([this.f]);
  factory _A.named([int? a]) = _A;
}
f() => _A.named(0);
''');
  }

  test_parameter_isUsed_fieldFormal_superInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? e;
  _A([this.e]);
}

class _B extends _A {
  _B(int e) : super(e);
}

var b = _B(1);
''');
  }

  test_parameter_isUsed_fieldFormal_superParameter() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? e;
  _A([this.e]);
}

class _B extends _A {
  _B(super.e);
}

var b = _B(2);
''');
  }

  test_parameter_isUsed_functionTearoff() async {
    await assertNoErrorsInCode(r'''
f() {
  void _m([int? a]) {}
  _m;
}
''');
  }

  test_parameter_isUsed_genericConstructor() async {
    await assertNoErrorsInCode('''
class C<T> {
  C._([int? x]);
}
void foo() {
  C._(7);
}
''');
  }

  test_parameter_isUsed_genericFunction() async {
    await assertNoErrorsInCode('''
void _f<T>([int? x]) {}
void foo() {
  _f(7);
}
''');
  }

  test_parameter_isUsed_genericMethod() async {
    await assertNoErrorsInCode('''
class C {
  void _m<T>([int? x]) {}
}
void foo() {
  C()._m(7);
}
''');
  }

  test_parameter_isUsed_local() async {
    await assertNoErrorsInCode(r'''
f() {
  void _m([int? a]) {}
  _m(1);
}
''');
  }

  test_parameter_isUsed_methodTearoff() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m([int? a]) {}
}
f() => A()._m;
''');
  }

  test_parameter_isUsed_named() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m({int a = 0}) {}
}
f() => A()._m(a: 0);
''');
  }

  test_parameter_isUsed_named_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A({this.f});
}
f() => _A(f: 1);
''');
  }

  test_parameter_isUsed_named_fieldFormal_constructorInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A({this.f});
}
f() => _A(f: 0);
''');
  }

  test_parameter_isUsed_named_fieldFormal_factoryRedirect() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? f;
  _A({this.f});
  factory _A.named({int? f}) = _A;
}
f() => _A.named(f: 0);
''');
  }

  test_parameter_isUsed_named_fieldFormal_superInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? e;
  _A({this.e});
}

class _B extends _A {
  _B([int? e]) : super(e: 1);
}

var b = _B(1);
''');
  }

  test_parameter_isUsed_named_fieldFormal_superParameter() async {
    await assertNoErrorsInCode(r'''
class _A {
  final int? e;
  _A({this.e});
}

class _B extends _A {
  _B({super.e});
}

var b = _B(e: 2);
''');
  }

  test_parameter_isUsed_named_superFormal() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A({int? a});
}

class B extends _A {
  B({super.a});
}
''');
  }

  test_parameter_isUsed_overridden() async {
    await assertErrorsInCode(
      r'''
class A {
  void _m([int? a]) {}
}
class B implements A {
  void _m([int? a]) {}
}
f() {
  A()._m();
  B()._m(0);
}
''',
      [error(diag.unusedElementParameter, 26, 1)],
    );
  }

  test_parameter_isUsed_override() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m([int? a]) {}
}
class B implements A {
  void _m([int? a]) {}
}
f() => A()._m(0);
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_parameter_isUsed_override_inAugmentation() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m([int? a]) {}
}
class B implements A {}
augment class B {
  void _m([int? a]) {}
}
f() => A()._m(0);
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_parameter_isUsed_override_ofAugmentation() async {
    await assertNoErrorsInCode(r'''
class A {
}
augment class A {
  void _m([int? a]) {}
}
class B implements A {
  void _m([int? a]) {}
}
f() => A()._m(0);
''');
  }

  test_parameter_isUsed_override_renamed() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m([int? a]) {}
}
class B implements A {
  void _m([int? b]) {}
}
f() => A()._m(0);
''');
  }

  test_parameter_isUsed_overrideRequired() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m(int a) {}
}
class B implements A {
  void _m([int? a]) {}
}
f() => A()._m(0);
''');
  }

  test_parameter_isUsed_overrideRequiredNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m({required int a}) {}
}
class B implements A {
  void _m({int a = 0}) {}
}
f() => A()._m(a: 0);
''');
  }

  test_parameter_isUsed_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m([int? a]) {}
}
f() => A()._m(0);
''');
  }

  test_parameter_isUsed_publicMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  void m([int? a]) {}
}
f() => A().m();
''');
  }

  test_parameter_isUsed_publicMethod_extension() async {
    await assertNoErrorsInCode(r'''
extension E on String {
  void m([int? a]) {}
}
f() => "hello".m();
''');
  }

  test_parameter_isUsed_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  void _m(int a) {}
}
f() => A()._m(0);
''');
  }

  test_parameter_isUsed_superFormal() async {
    await assertNoErrorsInCode(r'''
class _A {
  _A([int? a]);
}

class B extends _A {
  B([super.a]);
}
''');
  }

  test_parameter_isUsed_topLevel() async {
    await assertNoErrorsInCode(r'''
void _m([int? a]) {}
f() => _m(1);
''');
  }

  test_parameter_isUsed_topLevelPublic() async {
    await assertNoErrorsInCode(r'''
void m([int? a]) {}
f() => m();
''');
  }

  test_parameter_missingName_isNamed_redirectingFactory_source() async {
    await assertErrorsInCode(
      r'''
class C {
  C.impl({int? x});
  factory C({}) = C.impl;
}
''',
      [
        error(diag.missingIdentifier, 43, 1),
        error(diag.redirectToInvalidFunctionType, 48, 6),
      ],
    );
  }

  test_parameter_missingName_isNamed_redirectingFactory_target() async {
    await assertErrorsInCode(
      r'''
class C {
  C.impl({});
  factory C({int? x}) = C.impl;
}
''',
      [
        error(diag.missingIdentifier, 20, 1),
        error(diag.redirectToInvalidFunctionType, 48, 6),
      ],
    );
  }

  test_parameter_notUsed_constructor_named() async {
    await assertErrorsInCode(
      r'''
class A {
  A._([int? a]);
}
f() => A._();
''',
      [error(diag.unusedElementParameter, 22, 1)],
    );
  }

  test_parameter_notUsed_constructor_unnamed() async {
    await assertErrorsInCode(
      r'''
class _A {
  _A([int? a]);
}
f() => _A();
''',
      [error(diag.unusedElementParameter, 22, 1)],
    );
  }

  test_parameter_notUsed_extension() async {
    await assertErrorsInCode(
      r'''
extension E on String {
  void _m([int? a]) {}
}
f() => "hello"._m();
''',
      [error(diag.unusedElementParameter, 40, 1)],
    );
  }

  test_parameter_notUsed_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class _A {
  final int? f;
  _A([this.f]);
}
f() => _A();
''',
      [error(diag.unusedElementParameter, 38, 1)],
    );
  }

  test_parameter_notUsed_fieldFormal_factoryRedirect() async {
    await assertErrorsInCode(
      r'''
class _A {
  final int? f;
  _A([this.f]);
  factory _A.named() = _A;
}
f() => _A.named();
''',
      [error(diag.unusedElementParameter, 38, 1)],
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/47839')
  test_parameter_notUsed_genericConstructor() async {
    // TODO(srawlins): Change to assertErrorsInCode when this is fixed.
    addTestFile('''
class C<T> {
  C._([int? x]);
}
void foo() {
  C._();
}
''');
    await resolveTestFile();
    expect(result.diagnostics, isNotEmpty);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/47839')
  test_parameter_notUsed_genericFunction() async {
    // TODO(srawlins): Change to assertErrorsInCode when this is fixed.
    addTestFile('''
void _f<T>([int? x]) {}
void foo() {
  _f();
}
''');
    await resolveTestFile();
    expect(result.diagnostics, isNotEmpty);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/47839')
  test_parameter_notUsed_genericMethod() async {
    // TODO(srawlins): Change to assertErrorsInCode when this is fixed.
    addTestFile('''
class C {
  void _m<T>([int? x]) {}
}
void foo() {
  C()._m();
}
''');
    await resolveTestFile();
    expect(result.diagnostics, isNotEmpty);
  }

  test_parameter_notUsed_named() async {
    await assertErrorsInCode(
      r'''
class A {
  void _m({int? a}) {}
}
f() => A()._m();
''',
      [error(diag.unusedElementParameter, 26, 1)],
    );
  }

  test_parameter_notUsed_named_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class _A {
  final int? f;
  _A({this.f});
}
f() => _A();
''',
      [error(diag.unusedElementParameter, 38, 1)],
    );
  }

  test_parameter_notUsed_named_fieldFormal_factoryRedirect() async {
    await assertErrorsInCode(
      r'''
class _A {
  final int? f;
  _A({this.f});
  factory _A.named() = _A;
}
f() => _A.named();
''',
      [error(diag.unusedElementParameter, 38, 1)],
    );
  }

  test_parameter_notUsed_override_added() async {
    await assertErrorsInCode(
      r'''
class A {
  void _m() {}
}
class B implements A {
  void _m([int? a]) {}
}
f() => A()._m();
''',
      [error(diag.unusedElementParameter, 66, 1)],
    );
  }

  test_parameter_notUsed_overrideRequired() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required this.a, required this.b});
  final String a;
  final String b;
}

class _B extends A {
  _B({required super.a, super.b = 'b'});
}

var foo = _B(a: 'a');
''');
  }

  test_parameter_notUsed_positional() async {
    await assertErrorsInCode(
      r'''
class A {
  void _m([int? a]) {}
}
f() => A()._m();
''',
      [error(diag.unusedElementParameter, 26, 1)],
    );
  }

  test_parameter_notUsed_publicMethod_privateExtension() async {
    await assertErrorsInCode(
      r'''
extension _E on String {
  void m([int? a]) {}
}
f() => "hello".m();
''',
      [error(diag.unusedElementParameter, 40, 1)],
    );
  }

  test_parameter_notUsed_publicMethod_unnamedExtension() async {
    await assertErrorsInCode(
      r'''
extension on String {
  void m([int? a]) {}
}
f() => "hello".m();
''',
      [error(diag.unusedElementParameter, 37, 1)],
    );
  }

  test_parameter_notUsed_static() async {
    await assertErrorsInCode(
      r'''
class A {
  static void _m([int? a]) {}
}
f() => A._m();
''',
      [error(diag.unusedElementParameter, 33, 1)],
    );
  }

  test_parameter_notUsed_staticPublic_privateClass() async {
    await assertErrorsInCode(
      r'''
class _A {
  static void m([int? a]) {}
}
f() => _A.m();
''',
      [error(diag.unusedElementParameter, 33, 1)],
    );
  }

  test_parameter_notUsed_topLevel() async {
    await assertErrorsInCode(
      r'''
void _m([int? a]) {}
f() => _m();
''',
      [error(diag.unusedElementParameter, 14, 1)],
    );
  }

  test_privateEnum_privateConstructor_isUsed_redirect() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v._foo();
  const _E._foo() : this._bar();
  const _E._bar();
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_privateConstructor_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v._foo();
  const _E._foo();
  const _E._bar();
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 52, 4)],
    );
  }

  test_privateEnum_privateInstanceGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  int get _foo => 0;
}

void f() {
  _E.v._foo;
}
''');
  }

  test_privateEnum_privateInstanceGetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  int get _foo => 0;
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 25, 4)],
    );
  }

  test_privateEnum_privateInstanceMethod_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void _foo() {}
}

void f() {
  _E.v._foo();
}
''');
  }

  test_privateEnum_privateInstanceMethod_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  void _foo() {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 22, 4)],
    );
  }

  test_privateEnum_privateInstanceMethod_optionalNamedParameter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void _foo({int? a}) {}
}

void f() {
  _E.v._foo(a: 0);
}
''');
  }

  test_privateEnum_privateInstanceMethod_optionalNamedParameter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  void _foo({int? a}) {}
}

void f() {
  _E.v._foo();
}
''',
      [error(diag.unusedElementParameter, 33, 1)],
    );
  }

  test_privateEnum_privateInstanceMethod_optionalPositionalParameter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void _foo([int? a]) {}
}

void f() {
  _E.v._foo(0);
}
''');
  }

  test_privateEnum_privateInstanceMethod_optionalPositionalParameter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  void _foo([int? a]) {}
}

void f() {
  _E.v._foo();
}
''',
      [error(diag.unusedElementParameter, 33, 1)],
    );
  }

  test_privateEnum_privateInstanceSetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  set _foo(int _) {}
}

void f() {
  _E.v._foo = 0;
}
''');
  }

  test_privateEnum_privateInstanceSetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  set _foo(int _) {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 21, 4)],
    );
  }

  test_privateEnum_privateStaticGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static int get _foo => 0;
}

void f() {
  _E.v;
  _E._foo;
}
''');
  }

  test_privateEnum_privateStaticGetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static int get _foo => 0;
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 32, 4)],
    );
  }

  test_privateEnum_privateStaticMethod_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static void _foo() {}
}

void f() {
  _E.v;
  _E._foo();
}
''');
  }

  test_privateEnum_privateStaticMethod_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static void _foo() {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 29, 4)],
    );
  }

  test_privateEnum_privateStaticSetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static set _foo(int _) {}
}

void f() {
  _E.v;
  _E._foo = 0;
}
''');
  }

  test_privateEnum_privateStaticSetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static set _foo(int _) {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 28, 4)],
    );
  }

  test_privateEnum_publicConstructor_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v.foo();
  const _E.foo();
  const _E.bar();
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 50, 3)],
    );
  }

  test_privateEnum_publicInstanceGetter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  int get foo => 0;
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_publicInstanceMethod_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void foo() {}
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_publicInstanceMethod_optionalNamedParameter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void foo({int? a}) {}
}

void f() {
  _E.v.foo();
}
''');
  }

  test_privateEnum_publicInstanceMethod_optionalPositionalParameter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  void foo([int? a]) {}
}

void f() {
  _E.v.foo();
}
''');
  }

  test_privateEnum_publicInstanceSetter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  set foo(int _) {}
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_publicStaticGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static int get foo => 0;
}

void f() {
  _E.v;
  _E.foo;
}
''');
  }

  test_privateEnum_publicStaticGetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static int get foo => 0;
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 32, 3)],
    );
  }

  test_privateEnum_publicStaticMethod_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static void foo() {}
}

void f() {
  _E.v;
  _E.foo();
}
''');
  }

  test_privateEnum_publicStaticMethod_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static void foo() {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 29, 3)],
    );
  }

  test_privateEnum_publicStaticSetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static set foo(int _) {}
}

void f() {
  _E.v;
  _E.foo = 0;
}
''');
  }

  test_privateEnum_publicStaticSetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum _E {
  v;
  static set foo(int _) {}
}

void f() {
  _E.v;
}
''',
      [error(diag.unusedElement, 28, 3)],
    );
  }

  test_publicEnum_privateConstructor_isUsed_redirect() async {
    await assertNoErrorsInCode(r'''
enum E {
  v._foo();
  const E._foo() : this._bar();
  const E._bar();
}
''');
  }

  test_publicEnum_privateConstructor_notExposedViaTypeAlias() async {
    await assertNoErrorsInCode(r'''
enum _E {
  one(), two();
  const _E();
  const _E.named();
}
typedef T = _E;
void f() {
  _E.one;
  _E.two;
}
''');
  }

  test_publicEnum_privateConstructor_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v._foo();
  const E._foo();
  const E._bar();
}
''',
      [error(diag.unusedElement, 49, 4)],
    );
  }

  test_publicEnum_privateStaticGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int get _foo => 0;
}

void f() {
  E._foo;
}
''');
  }

  test_publicEnum_privateStaticGetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get _foo => 0;
}
''',
      [error(diag.unusedElement, 31, 4)],
    );
  }

  test_publicEnum_privateStaticMethod_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static void _foo() {}
}

void f() {
  E._foo();
}
''');
  }

  test_publicEnum_privateStaticMethod_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void _foo() {}
}
''',
      [error(diag.unusedElement, 28, 4)],
    );
  }

  test_publicEnum_privateStaticSetter_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static set _foo(int _) {}
}

void f() {
  E._foo = 0;
}
''');
  }

  test_publicEnum_privateStaticSetter_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static set _foo(int _) {}
}
''',
      [error(diag.unusedElement, 27, 4)],
    );
  }

  test_publicEnum_publicConstructor_isUsed_generic() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v1<int>.named(),
  v2<int>.renamed();

  const E.named();
  const E.renamed() : this.named();
}
''');
  }

  test_publicEnum_publicConstructor_isUsed_redirect() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo() : this.bar();
  const E.bar();
}
''');
  }

  test_publicEnum_publicConstructor_notUsed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  const E.bar();
}
''',
      [error(diag.unusedElement, 47, 3)],
    );
  }

  test_publicEnum_publicStaticGetter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_publicEnum_publicStaticMethod_notUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_publicEnum_publicStaticSetter_notUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_publicStaticMethod_privateClass_isUsed() async {
    await assertNoErrorsInCode(r'''
class _A {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateClass_notUsed() async {
    await assertErrorsInCode(
      r'''
class _A {
  static void m() {}
}
void f(_A a) {}
''',
      [error(diag.unusedElement, 25, 1)],
    );
  }

  test_publicStaticMethod_privateExtension_isUsed() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateExtension_notUsed() async {
    await assertErrorsInCode(
      r'''
extension _A on String {
  static void m() {}
}
''',
      [error(diag.unusedElement, 39, 1)],
    );
  }

  test_publicStaticMethod_privateMixin_isUsed() async {
    await assertNoErrorsInCode(r'''
mixin _A {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateMixin_notUsed() async {
    await assertErrorsInCode(
      r'''
mixin _A {
  static void m() {}
}
void main() {
  _A;
}
''',
      [error(diag.unusedElement, 25, 1)],
    );
  }

  test_publicTopLevelFunction_notUsed() async {
    await assertNoErrorsInCode(r'''
int get a => 1;
''');
  }

  test_setter_isUsed_invocation_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
  useSetter() {
    _s = 42;
  }
}
''');
  }

  test_setter_isUsed_invocation_PrefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
}
void f(A a) {
  a._s = 42;
}
''');
  }

  test_setter_isUsed_invocation_PropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
}
main() {
  new A()._s = 42;
}
''');
  }

  test_setter_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
class A {
  set _s(x) {}
}
''',
      [error(diag.unusedElement, 16, 2)],
    );
  }

  test_setter_notUsed_referenceFromItself() async {
    await assertErrorsInCode(
      r'''
class A {
  set _s(int x) {
    if (x > 5) {
      _s = x - 1;
    }
  }
}
''',
      [error(diag.unusedElement, 16, 2)],
    );
  }

  test_topLevelAccessors_isUsed_questionQuestionEqual() async {
    await assertNoErrorsInCode(r'''
int? get _c => 1;
void set _c(int? x) {}
int f() {
  return _c ??= 7;
}
''');
  }

  test_topLevelFunction_isUsed_hasPragma_vmEntryPoint() async {
    await assertNoErrorsInCode(r'''
@pragma('vm:entry-point')
void _f() {}
''');
  }

  test_topLevelFunction_isUsed_invocation() async {
    await assertNoErrorsInCode(r'''
_f() {}
main() {
  _f();
}
''');
  }

  test_topLevelFunction_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
_f() {}
main() {
  print(_f);
}
print(x) {}
''');
  }

  test_topLevelFunction_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
_f() {}
main() {
}
''',
      [error(diag.unusedElement, 0, 2)],
    );
  }

  test_topLevelFunction_notUsed_referenceFromItself() async {
    await assertErrorsInCode(
      r'''
_f(int p) {
  _f(p - 1);
}
main() {
}
''',
      [error(diag.unusedElement, 0, 2)],
    );
  }

  test_topLevelFunction_notUsed_referenceInComment() async {
    await assertErrorsInCode(
      r'''
/// [_f] is a great function.
_f(int p) => 7;
''',
      [error(diag.unusedElement, 30, 2)],
    );
  }

  test_topLevelGetterSetter_isUsed_assignmentExpression_compound() async {
    await assertNoErrorsInCode(r'''
int get _foo => 0;
set _foo(int _) {}

void f() {
  _foo += 2;
}
''');
  }

  test_topLevelGetterSetter_isUsed_postfixExpression_increment() async {
    await assertNoErrorsInCode(r'''
int get _foo => 0;
set _foo(int _) {}

void f() {
  _foo++;
}
''');
  }

  test_topLevelGetterSetter_isUsed_prefixExpression_increment() async {
    await assertNoErrorsInCode(r'''
int get _foo => 0;
set _foo(int _) {}

void f() {
  ++_foo;
}
''');
  }

  test_topLevelSetter_isUsed_assignmentExpression_simple() async {
    await assertNoErrorsInCode(r'''
set _foo(int _) {}

void f() {
  _foo = 0;
}
''');
  }

  test_topLevelSetter_notUsed() async {
    await assertErrorsInCode(
      r'''
set _foo(int _) {}
''',
      [error(diag.unusedElement, 4, 4)],
    );
  }

  test_topLevelVariable_isUsed() async {
    await assertNoErrorsInCode(r'''
int _a = 1;
main() {
  _a;
}
''');
  }

  test_topLevelVariable_isUsed_plusPlus() async {
    await assertNoErrorsInCode(r'''
int _a = 0;
main() {
  var b = _a++;
  b;
}
''');
  }

  test_topLevelVariable_isUsed_questionQuestionEqual() async {
    await assertNoErrorsInCode(r'''
int? _a;
f() {
  _a ??= 1;
}
''');
  }

  test_topLevelVariable_notUsed() async {
    await assertErrorsInCode(
      r'''
int _a = 1;
main() {
  _a = 2;
}
''',
      [error(diag.unusedElement, 4, 2)],
    );
  }

  test_topLevelVariable_notUsed_compoundAssign() async {
    await assertErrorsInCode(
      r'''
int _a = 1;
f() {
  _a += 1;
}
''',
      [error(diag.unusedElement, 4, 2)],
    );
  }

  test_topLevelVariable_notUsed_referenceInComment() async {
    await assertErrorsInCode(
      r'''
/// [_a] is a great variable.
int _a = 7;
''',
      [error(diag.unusedElement, 34, 2)],
    );
  }

  test_typeAlias_functionType_isUsed_isExpression() async {
    await assertNoErrorsInCode(r'''
typedef _F = void Function();
main(f) {
  if (f is _F) {
    print('F');
  }
}
''');
  }

  test_typeAlias_functionType_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
typedef _F = void Function();
void f(_F f) {
}
''');
  }

  test_typeAlias_functionType_isUsed_typeArgument() async {
    await assertNoErrorsInCode(r'''
typedef _F = void Function();
main() {
  var v = new List<_F>.empty();
  print(v);
}
''');
  }

  test_typeAlias_functionType_isUsed_variableDeclaration() async {
    await assertNoErrorsInCode(r'''
typedef _F = void Function();
class A {
  _F? f;
}
''');
  }

  test_typeAlias_functionType_notUsed_noReference() async {
    await assertErrorsInCode(
      r'''
typedef _F = void Function();
main() {
}
''',
      [error(diag.unusedElement, 8, 2)],
    );
  }

  test_typeAlias_interfaceType_isUsed_typeName_isExpression() async {
    await assertNoErrorsInCode(r'''
typedef _A = List<int>;

void f(a) {
  a is _A;
}
''');
  }

  test_typeAlias_interfaceType_isUsed_typeName_parameter() async {
    await assertNoErrorsInCode(r'''
typedef _A = List<int>;

void f(_A a) {}
''');
  }

  test_typeAlias_interfaceType_isUsed_typeName_typeArgument() async {
    await assertNoErrorsInCode(r'''
typedef _A = List<int>;

void f() {
  Map<_A, int>();
}
''');
  }

  test_typeAlias_interfaceType_notUsed() async {
    await assertErrorsInCode(
      r'''
typedef _A = List<int>;
''',
      [error(diag.unusedElement, 8, 2)],
    );
  }
}
