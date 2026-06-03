// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var f = this;
//        ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_instanceField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  late var f = this;
}
''');
  }

  test_class_instanceGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_class_instanceMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {
    this;
  }
}
''');
  }

  test_class_instanceMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo([Object p = this]) {}
//                     ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_instanceSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_class_primaryConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int a) {
  this : assert(this.hashCode == 0);
//              ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_primaryConstructor_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(num a) {
  num f = 0;
  this {
    this.f = a;
  }
}
''');
  }

  test_class_primaryConstructor_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A([int p = this]) {}
//               ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
''');
  }

  test_class_primaryConstructor_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  var f;
  this : f = this;
//           ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_primaryConstructor_superInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(Object x);
class B() extends A {
  this : super(this);
//             ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_factory_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() { return this; }
//                     ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_factory_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A([Object p = this]) => throw 0;
//                      ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_generative_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : assert(this.hashCode == 0);
//             ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_generative_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {
    var v = this;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  }
}
''');
  }

  test_class_secondaryConstructor_generative_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([Object p = this]);
//              ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_generative_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var f;
  A() : f = this;
//          ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_generative_redirectingInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(Object x);
  A.named() : this(this);
//                 ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_secondaryConstructor_generative_superInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(x) {}
}
class B extends A {
  B() : super(this);
//            ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_staticField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static A f = this;
//             ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_staticField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static late var f = this;
//                    ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_staticGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
    return 0;
  }
}
''');
  }

  test_class_staticMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_class_staticMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo([Object p = this]) {}
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_class_staticSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_enum_instanceField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final f = this;
//          ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_instanceField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  late final f = this;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_enum_instanceGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {
    this;
  }
}
''');
  }

  test_enum_instanceMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo([Object p = this]) {}
//                     ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_instanceSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set foo(int _) {
    this;
  }
}
''');
  }

  test_enum_primaryConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this : assert(this.hashCode == 0);
//              ^^^^^^^^^^^^^
// [diag.invalidConstant] Invalid constant value.
//              ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_primaryConstructor_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this {
//     ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
    this;
  }
}
''');
  }

  test_enum_primaryConstructor_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E([int p = this]) {
//          ^
// [diag.unusedElementParameter] A value for optional parameter 'p' isn't ever given.
//              ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  v;
}
''');
  }

  test_enum_primaryConstructor_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  final Object f;
  this : f = this;
//           ^^^^
// [diag.invalidConstant] Invalid constant value.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_secondaryConstructor_factory_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.named() {
    return this;
//         ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_enum_secondaryConstructor_factory_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.named([Object p = this]) => throw 0;
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_secondaryConstructor_generative_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const E.named() : assert(this.hashCode == 0);
//                         ^^^^^^^^^^^^^
// [diag.invalidConstant] Invalid constant value.
//                         ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_secondaryConstructor_generative_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const E.named() {
//                ^
// [diag.constConstructorWithBody] Const constructors can't have a body.
    this;
  }
}
''');
  }

  test_enum_secondaryConstructor_generative_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const E.named([Object p = this]);
//                      ^
// [diag.unusedElementParameter] A value for optional parameter 'p' isn't ever given.
//                          ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_secondaryConstructor_generative_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final Object f;
  const E() : f = this;
//                ^^^^
// [diag.invalidConstant] Invalid constant value.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_secondaryConstructor_generative_redirectingInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const E.named() : this(this);
//                       ^^^^
// [diag.invalidConstant] Invalid constant value.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  const E(Object o);
}
''');
  }

  test_enum_staticField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static var f = this;
//               ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_staticField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static late final f = this;
//                      ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_staticGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
    return 0;
  }
}
''');
  }

  test_enum_staticMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_enum_staticMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo([Object p = this]) {}
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_enum_staticSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _) {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_extension_instanceGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_extension_instanceMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {
    this;
  }
}
''');
  }

  test_extension_instanceMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo([Object p = this]) {}
//                     ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extension_instanceSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_extension_staticField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static var f = this;
//               ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extension_staticField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static late var f = this;
//                    ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extension_staticGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
    return 0;
  }
}
''');
  }

  test_extension_staticMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_extension_staticMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo([Object p = this]) {}
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extension_staticSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _) {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_extensionType_instanceGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_extensionType_instanceMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void foo() {
    this;
  }
}
''');
  }

  test_extensionType_instanceMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void foo([Object p = this]) {}
//                     ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidAssignment] A value of type 'E' can't be assigned to a variable of type 'Object'.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_instanceSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_extensionType_primaryConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  this : assert(this.hashCode == 0);
//              ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_primaryConstructor_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  this {
    this;
  }
}
''');
  }

  test_extensionType_primaryConstructor_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E([int it = this]) {}
//                         ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
''');
  }

  test_extensionType_primaryConstructor_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  this : it = this.hashCode;
//       ^^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
//            ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_secondaryConstructor_factory_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  factory E.named() {
    return this;
//         ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_extensionType_secondaryConstructor_factory_defaultValue() async {
    await resolveTestCodeWithDiagnostics('''
extension type E(int it) {
  factory E.named([Object p = this]) => throw 0;
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidAssignment] A value of type 'E' can't be assigned to a variable of type 'Object'.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_assertInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type E(int it) {
  E.named() : it = 0, assert(this.hashCode == 0);
//                           ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named() : it = 0 {
    this;
  }
}
''');
  }

  test_extensionType_secondaryConstructor_generative_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named([Object p = this]) : it = 0;
//                    ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidAssignment] A value of type 'E' can't be assigned to a variable of type 'Object'.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named() : it = this.hashCode;
//                 ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_redirectingInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named() : this(this.hashCode);
//                 ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_staticField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static var f = this;
//               ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_staticField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static late var f = this;
//                    ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_staticGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get foo {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
    return 0;
  }
}
''');
  }

  test_extensionType_staticMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo() {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_extensionType_staticMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo([Object p = this]) {}
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidAssignment] A value of type 'E' can't be assigned to a variable of type 'Object'.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_extensionType_staticSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static set foo(int _) {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_mixin_instanceField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  var f = this;
//        ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_mixin_instanceField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  late var f = this;
}
''');
  }

  test_mixin_instanceGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo {
    this;
    return 0;
  }
}
''');
  }

  test_mixin_instanceMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {
    this;
  }
}
''');
  }

  test_mixin_instanceMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo([Object p = this]) {}
//                     ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_mixin_instanceSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {
    this;
  }
}
''');
  }

  test_mixin_staticField_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static var f = this;
//               ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_mixin_staticField_lateInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static late var f = this;
//                    ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_mixin_staticGetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
    return 0;
  }
}
''');
  }

  test_mixin_staticMethod_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_mixin_staticMethod_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo([Object p = this]) {}
//                            ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_mixin_staticSetter_body() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _) {
    this;
//  ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  }
}
''');
  }

  test_topLevelFunction__body() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  this;
//^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_topLevelFunction__defaultValue() async {
    await resolveTestCodeWithDiagnostics('''
void f([Object p = this]) {}
//                 ^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
''');
  }

  test_topLevelGetter_body() async {
    await resolveTestCodeWithDiagnostics('''
int get f {
  this;
//^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
  return 0;
}
''');
  }

  test_topLevelSetter_body() async {
    await resolveTestCodeWithDiagnostics('''
set f(int _) {
  this;
//^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
}
''');
  }

  test_topLevelVariable_initializer() async {
    await resolveTestCodeWithDiagnostics('''
int f = this;
//      ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
''');
  }

  test_topLevelVariable_lateInitializer() async {
    await resolveTestCodeWithDiagnostics('''
late var f = this;
//           ^^^^
// [diag.invalidReferenceToThis] Invalid reference to 'this' expression.
''');
  }
}
