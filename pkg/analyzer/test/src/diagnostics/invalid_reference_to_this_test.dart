// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidReferenceToThisTest);
  });
}

@reflectiveTest
class InvalidReferenceToThisTest extends PubPackageResolutionTest {
  test_class_instanceField_initializer() async {
    await assertErrorsInCode(
      r'''
class A {
  var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 20, 4)],
    );
  }

  test_class_instanceField_lateInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  late var f = this;
}
''');
  }

  test_class_instanceGetter_body() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_class_instanceMethod_body() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {
    this;
  }
}
''');
  }

  test_class_instanceMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 33, 4),
        error(diag.invalidReferenceToThis, 33, 4),
      ],
    );
  }

  test_class_instanceSetter_body() async {
    await assertNoErrorsInCode(r'''
class A {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_class_primaryConstructor_assertInitializer() async {
    await assertErrorsInCode(
      r'''
class A(int a) {
  this : assert(this.hashCode == 0);
}
''',
      [error(diag.invalidReferenceToThis, 33, 4)],
    );
  }

  test_class_primaryConstructor_body() async {
    await assertNoErrorsInCode(r'''
class A(num a) {
  num f = 0;
  this {
    this.f = a;
  }
}
''');
  }

  test_class_primaryConstructor_defaultValue() async {
    await assertErrorsInCode(
      r'''
class A([int p = this]) {}
''',
      [
        error(diag.nonConstantDefaultValue, 17, 4),
        error(diag.invalidReferenceToThis, 17, 4),
      ],
    );
  }

  test_class_primaryConstructor_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
class A() {
  var f;
  this : f = this;
}
''',
      [error(diag.invalidReferenceToThis, 34, 4)],
    );
  }

  test_class_primaryConstructor_superInitializer() async {
    await assertErrorsInCode(
      r'''
class A(Object x);
class B() extends A {
  this : super(this);
}
''',
      [error(diag.invalidReferenceToThis, 56, 4)],
    );
  }

  test_class_secondaryConstructor_factory_body() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() { return this; }
}
''',
      [error(diag.invalidReferenceToThis, 33, 4)],
    );
  }

  test_class_secondaryConstructor_factory_defaultValue() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A([Object p = this]) => throw 0;
}
''',
      [
        error(diag.nonConstantDefaultValue, 34, 4),
        error(diag.invalidReferenceToThis, 34, 4),
      ],
    );
  }

  test_class_secondaryConstructor_generative_assertInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : assert(this.hashCode == 0);
}
''',
      [error(diag.invalidReferenceToThis, 25, 4)],
    );
  }

  test_class_secondaryConstructor_generative_body() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {
    var v = this;
  }
}
''',
      [error(diag.unusedLocalVariable, 26, 1)],
    );
  }

  test_class_secondaryConstructor_generative_defaultValue() async {
    await assertErrorsInCode(
      r'''
class A {
  A([Object p = this]);
}
''',
      [
        error(diag.nonConstantDefaultValue, 26, 4),
        error(diag.invalidReferenceToThis, 26, 4),
      ],
    );
  }

  test_class_secondaryConstructor_generative_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  var f;
  A() : f = this;
}
''',
      [error(diag.invalidReferenceToThis, 31, 4)],
    );
  }

  test_class_secondaryConstructor_generative_redirectingInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  A(Object x);
  A.named() : this(this);
}
''',
      [error(diag.invalidReferenceToThis, 44, 4)],
    );
  }

  test_class_secondaryConstructor_generative_superInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  A(x) {}
}
class B extends A {
  B() : super(this);
}
''',
      [error(diag.invalidReferenceToThis, 56, 4)],
    );
  }

  test_class_staticField_initializer() async {
    await assertErrorsInCode(
      r'''
class A {
  static A f = this;
}
''',
      [error(diag.invalidReferenceToThis, 25, 4)],
    );
  }

  test_class_staticField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  static late var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 32, 4)],
    );
  }

  test_class_staticGetter_body() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get foo {
    this;
    return 0;
  }
}
''',
      [error(diag.invalidReferenceToThis, 37, 4)],
    );
  }

  test_class_staticMethod_body() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 36, 4)],
    );
  }

  test_class_staticMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 40, 4),
        error(diag.invalidReferenceToThis, 40, 4),
      ],
    );
  }

  test_class_staticSetter_body() async {
    await assertErrorsInCode(
      r'''
class A {
  static set foo(int _) {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 40, 4)],
    );
  }

  test_enum_instanceField_initializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final f = this;
}
''',
      [error(diag.invalidReferenceToThis, 26, 4)],
    );
  }

  test_enum_instanceField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  late final f = this;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 16, 4)],
    );
  }

  test_enum_instanceGetter_body() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_enum_instanceMethod_body() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  void foo() {
    this;
  }
}
''');
  }

  test_enum_instanceMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 37, 4),
        error(diag.invalidReferenceToThis, 37, 4),
      ],
    );
  }

  test_enum_instanceSetter_body() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  set foo(int _) {
    this;
  }
}
''');
  }

  test_enum_primaryConstructor_assertInitializer() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  this : assert(this.hashCode == 0);
}
''',
      [error(diag.invalidReferenceToThis, 32, 4)],
    );
  }

  test_enum_primaryConstructor_body() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  this {
    this;
  }
}
''',
      [error(diag.constConstructorWithBody, 23, 1)],
    );
  }

  test_enum_primaryConstructor_defaultValue() async {
    await assertErrorsInCode(
      r'''
enum E([int p = this]) {
  v;
}
''',
      [
        error(diag.unusedElementParameter, 12, 1),
        error(diag.nonConstantDefaultValue, 16, 4),
        error(diag.invalidReferenceToThis, 16, 4),
      ],
    );
  }

  test_enum_primaryConstructor_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  final Object f;
  this : f = this;
}
''',
      [error(diag.invalidReferenceToThis, 47, 4)],
    );
  }

  test_enum_secondaryConstructor_factory_body() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  factory E.named() {
    return this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 47, 4)],
    );
  }

  test_enum_secondaryConstructor_factory_defaultValue() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  factory E.named([Object p = this]) => throw 0;
}
''',
      [
        error(diag.nonConstantDefaultValue, 44, 4),
        error(diag.invalidReferenceToThis, 44, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_generative_assertInitializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named();
  const E.named() : assert(this.hashCode == 0);
}
''',
      [
        error(diag.invalidConstant, 49, 13),
        error(diag.invalidReferenceToThis, 49, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_generative_body() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named();
  const E.named() {
    this;
  }
}
''',
      [error(diag.constConstructorWithBody, 40, 1)],
    );
  }

  test_enum_secondaryConstructor_generative_defaultValue() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named();
  const E.named([Object p = this]);
}
''',
      [
        error(diag.unusedElementParameter, 46, 1),
        error(diag.nonConstantDefaultValue, 50, 4),
        error(diag.invalidReferenceToThis, 50, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_generative_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final Object f;
  const E() : f = this;
}
''',
      [
        error(diag.invalidConstant, 50, 4),
        error(diag.invalidReferenceToThis, 50, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_generative_redirectingInitializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named();
  const E.named() : this(this);
  const E(Object o);
}
''',
      [
        error(diag.invalidConstant, 47, 4),
        error(diag.invalidReferenceToThis, 47, 4),
      ],
    );
  }

  test_enum_staticField_initializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 31, 4)],
    );
  }

  test_enum_staticField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static late final f = this;
}
''',
      [error(diag.invalidReferenceToThis, 38, 4)],
    );
  }

  test_enum_staticGetter_body() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get foo {
    this;
    return 0;
  }
}
''',
      [error(diag.invalidReferenceToThis, 41, 4)],
    );
  }

  test_enum_staticMethod_body() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 40, 4)],
    );
  }

  test_enum_staticMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 44, 4),
        error(diag.invalidReferenceToThis, 44, 4),
      ],
    );
  }

  test_enum_staticSetter_body() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static set foo(int _) {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 44, 4)],
    );
  }

  test_extension_instanceGetter_body() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_extension_instanceMethod_body() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  void foo() {
    this;
  }
}
''');
  }

  test_extension_instanceMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 44, 4),
        error(diag.invalidReferenceToThis, 44, 4),
      ],
    );
  }

  test_extension_instanceSetter_body() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_extension_staticField_initializer() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 38, 4)],
    );
  }

  test_extension_staticField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static late var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 43, 4)],
    );
  }

  test_extension_staticGetter_body() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static int get foo {
    this;
    return 0;
  }
}
''',
      [error(diag.invalidReferenceToThis, 48, 4)],
    );
  }

  test_extension_staticMethod_body() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static void foo() {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 47, 4)],
    );
  }

  test_extension_staticMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 51, 4),
        error(diag.invalidReferenceToThis, 51, 4),
      ],
    );
  }

  test_extension_staticSetter_body() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static set foo(int _) {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 51, 4)],
    );
  }

  test_extensionType_instanceGetter_body() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_extensionType_instanceMethod_body() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  void foo() {
    this;
  }
}
''');
  }

  test_extensionType_instanceMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 50, 4),
        error(diag.invalidAssignment, 50, 4),
        error(diag.invalidReferenceToThis, 50, 4),
      ],
    );
  }

  test_extensionType_instanceSetter_body() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_extensionType_primaryConstructor_assertInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  this : assert(this.hashCode == 0);
}
''',
      [error(diag.invalidReferenceToThis, 43, 4)],
    );
  }

  test_extensionType_primaryConstructor_body() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  this {
    this;
  }
}
''');
  }

  test_extensionType_primaryConstructor_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension type E([int it = this]) {}
''',
      [
        error(diag.invalidReferenceToThis, 27, 4),
        error(diag.nonConstantDefaultValue, 27, 4),
      ],
    );
  }

  test_extensionType_primaryConstructor_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  this : it = this.hashCode;
}
''',
      [
        error(diag.fieldInitializedInParameterAndInitializer, 36, 2),
        error(diag.invalidReferenceToThis, 41, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_factory_body() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  factory E.named() {
    return this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 60, 4)],
    );
  }

  test_extensionType_secondaryConstructor_factory_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  factory E.named([Object p = this]) => throw 0;
}
''',
      [
        error(diag.nonConstantDefaultValue, 57, 4),
        error(diag.invalidAssignment, 57, 4),
        error(diag.invalidReferenceToThis, 57, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_generative_assertInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  E.named() : it = 0, assert(this.hashCode == 0);
}
''',
      [error(diag.invalidReferenceToThis, 56, 4)],
    );
  }

  test_extensionType_secondaryConstructor_generative_body() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  E.named() : it = 0 {
    this;
  }
}
''');
  }

  test_extensionType_secondaryConstructor_generative_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  E.named([Object p = this]) : it = 0;
}
''',
      [
        error(diag.nonConstantDefaultValue, 49, 4),
        error(diag.invalidAssignment, 49, 4),
        error(diag.invalidReferenceToThis, 49, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_generative_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  E.named() : it = this.hashCode;
}
''',
      [error(diag.invalidReferenceToThis, 46, 4)],
    );
  }

  test_extensionType_secondaryConstructor_generative_redirectingInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  E.named() : this(this.hashCode);
}
''',
      [error(diag.invalidReferenceToThis, 46, 4)],
    );
  }

  test_extensionType_staticField_initializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 44, 4)],
    );
  }

  test_extensionType_staticField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static late var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 49, 4)],
    );
  }

  test_extensionType_staticGetter_body() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int get foo {
    this;
    return 0;
  }
}
''',
      [error(diag.invalidReferenceToThis, 54, 4)],
    );
  }

  test_extensionType_staticMethod_body() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void foo() {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 53, 4)],
    );
  }

  test_extensionType_staticMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 57, 4),
        error(diag.invalidAssignment, 57, 4),
        error(diag.invalidReferenceToThis, 57, 4),
      ],
    );
  }

  test_extensionType_staticSetter_body() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static set foo(int _) {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 57, 4)],
    );
  }

  test_mixin_instanceField_initializer() async {
    await assertErrorsInCode(
      r'''
mixin M {
  var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 20, 4)],
    );
  }

  test_mixin_instanceField_lateInitializer() async {
    await assertNoErrorsInCode(r'''
mixin A {
  late var f = this;
}
''');
  }

  test_mixin_instanceGetter_body() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_mixin_instanceMethod_body() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void foo() {
    this;
  }
}
''');
  }

  test_mixin_instanceMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 33, 4),
        error(diag.invalidReferenceToThis, 33, 4),
      ],
    );
  }

  test_mixin_instanceSetter_body() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_mixin_staticField_initializer() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 27, 4)],
    );
  }

  test_mixin_staticField_lateInitializer() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static late var f = this;
}
''',
      [error(diag.invalidReferenceToThis, 32, 4)],
    );
  }

  test_mixin_staticGetter_body() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo {
    this;
    return 0;
  }
}
''',
      [error(diag.invalidReferenceToThis, 37, 4)],
    );
  }

  test_mixin_staticMethod_body() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 36, 4)],
    );
  }

  test_mixin_staticMethod_defaultValue() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo([Object p = this]) {}
}
''',
      [
        error(diag.nonConstantDefaultValue, 40, 4),
        error(diag.invalidReferenceToThis, 40, 4),
      ],
    );
  }

  test_mixin_staticSetter_body() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static set foo(int _) {
    this;
  }
}
''',
      [error(diag.invalidReferenceToThis, 40, 4)],
    );
  }

  test_topLevelFunction__body() async {
    await assertErrorsInCode(
      '''
void f() {
  this;
}
''',
      [error(diag.invalidReferenceToThis, 13, 4)],
    );
  }

  test_topLevelFunction__defaultValue() async {
    await assertErrorsInCode(
      '''
void f([Object p = this]) {}
''',
      [
        error(diag.nonConstantDefaultValue, 19, 4),
        error(diag.invalidReferenceToThis, 19, 4),
      ],
    );
  }

  test_topLevelGetter_body() async {
    await assertErrorsInCode(
      '''
int get f {
  this;
  return 0;
}
''',
      [error(diag.invalidReferenceToThis, 14, 4)],
    );
  }

  test_topLevelSetter_body() async {
    await assertErrorsInCode(
      '''
set f(int _) {
  this;
}
''',
      [error(diag.invalidReferenceToThis, 17, 4)],
    );
  }

  test_topLevelVariable_initializer() async {
    await assertErrorsInCode(
      '''
int f = this;
''',
      [error(diag.invalidReferenceToThis, 8, 4)],
    );
  }

  test_topLevelVariable_lateInitializer() async {
    await assertErrorsInCode(
      '''
late var f = this;
''',
      [error(diag.invalidReferenceToThis, 13, 4)],
    );
  }
}
