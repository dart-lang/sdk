// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNotInitializedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VariableNotInitializedTest extends PubPackageResolutionTest {
  test_class_instanceField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const int v;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
//          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_final_abstract_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int v;
}
''');
  }

  test_class_instanceField1_final_abstract_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int v;
  A();
}
''');
  }

  test_class_instanceField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int v = 0;
//                   ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_class_instanceField1_final_external_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int v;
}
''');
  }

  test_class_instanceField1_final_external_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int v;
  A();
}
''');
  }

  test_class_instanceField1_final_functionTypedFieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final Function v;
  A(int this.v()) {}
}
''');
  }

  test_class_instanceField1_final_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final Object? v = 0;
}
''');
  }

  test_class_instanceField1_final_hasInitializer_primaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  final int v = 0;
  this : v = 0;
//       ^
// [diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor] Fields can't be initialized in both the primary constructor and at their declaration.
}
''');
  }

  test_class_instanceField1_final_hasInitializer_primaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v) {
//           ^
// [diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor] Fields can't be initialized in both the primary constructor parameter list and at their declaration.
  final int v = 0;
}
''');
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final Object? v = 0;
  A();
}
''');
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v = 0;
  A() : v = 0;
//      ^
// [diag.fieldInitializedInInitializerAndDeclaration] Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.
}
''');
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v = 0;
  A(this.v) {}
//       ^
// [diag.finalInitializedInDeclarationAndConstructor] 'v' is final and was given a value when it was declared, so it can't be set to a new value.
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final int v = 0;
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  late final int v = 0;
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class const A() {
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor_const_hasNotConst() async {
    await resolveTestCodeWithDiagnostics('''
class const A() {
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
  A.notConst() : this();
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final int v = 0;
  A();
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
  const A();
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor_const_hasNotConst() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
  const A();
  A.notConst();
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_factoryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class Base {
  Base();
  const factory Base.empty() = _Empty;
  late final int v;
}

class _Empty implements Base {
  const _Empty();
  int get v => 0;
  set v(_) {}
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final Object? v;
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_primaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class const A() {
  late final int v;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final Object? v;
  A();
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_secondaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late final int v;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
  const A();
}
''');
  }

  test_class_instanceField1_final_noInitializer_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
//          ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.

  factory A() => throw 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final Object? v;
//              ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  final int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_body0() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
//    ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
  final int v;
  this;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  final int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
//    ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
  final int v;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v) {
  final int v;
  this;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_noDeclaration_body1() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  this : v = 0;
//^^^^
// [diag.primaryConstructorBodyWithoutDeclaration] A primary constructor body requires a primary constructor declaration.
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final Object? v;
  A() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final Object? v;
  A(this.v);
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_named() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  A.named() {}
//^^^^^^^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  A.zero() : v = 0;
  A.one() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  A() {}
//^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_duplicateField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A();
  final int v;
//          ^
// [context 1] The first definition of this name.
  final int v;
//          ^
// [diag.duplicateDefinition][context 1] The name 'v' is already defined.
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetInitialized() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  A() : this._();
  A._() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetNotInitialized() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v;
  A() : this._();
  A._();
//^^^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
}
''');
  }

  test_class_instanceField1_notFinal_abstract_typeInt_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  abstract int v;
//^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'v' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_class_instanceField1_notFinal_external_typeDouble_noInitializer_struct() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:ffi';

final class A extends Struct {
  @Double()
  external double v;
}
''');
  }

  test_class_instanceField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int v = 0;
//             ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_class_instanceField1_notFinal_external_typeInt_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int v;
}
''');
  }

  test_class_instanceField1_notFinal_external_typeInt_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int v;
  A();
}
''');
  }

  test_class_instanceField1_notFinal_late_typeInt_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  late int v;
}
''');
  }

  test_class_instanceField1_notFinal_typeDynamic_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  dynamic v;
}
''');
  }

  test_class_instanceField1_notFinal_typeFutureOrIntQ_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

class A {
  FutureOr<int?> v;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v = 0;

  A(this.v);

  factory A.named() => A(0);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  int v = 0;
  this : v = 0;
//       ^
// [diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor] Fields can't be initialized in both the primary constructor and at their declaration.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v) {
//           ^
// [diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor] Fields can't be initialized in both the primary constructor parameter list and at their declaration.
  int v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.v) {
//           ^
// [diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor] Fields can't be initialized in both the primary constructor parameter list and at their declaration.
  int v = 0;
  this : v = 0;
//       ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v = 0;
  A() : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v = 0;
  A() : v = 0, v = 0 {}
//             ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v = 0;
  A(this.v);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v = 0;
  A(this.v) : v = 0 {}
//            ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'v' must be initialized.

  factory A() => throw 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_noConstructor_inferred() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get v;
}

class B extends A {
  var v;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_bodyWithoutDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v;
  this : v = 0;
//^^^^
// [diag.primaryConstructorBodyWithoutDeclaration] A primary constructor body requires a primary constructor declaration.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int v;
  this : v = 0, v = 0;
//              ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int v;
  this : v = 0, v = 0, v = 0;
//              ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
//                     ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v;

  A() : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v;
  A() : v = 0, v = 0 {}
//             ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v;
  A() : v = 0, v = 0, v = 0 {}
//             ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
//                    ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v;

  A(this.v);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v;
  A(this.v) : v = 0 {}
//            ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructors_notInitializedByAll() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v;

  A.foo(this.v);

  A.bar();
//^^^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_notFinal_typeIntQ_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int? v;
}
''');
  }

  test_class_instanceField1_notFinal_typeNever_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  Never v;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_notFinal_typeT_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  T v;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'v' must be initialized.
}
''');
  }

  test_class_instanceField1_notFinal_typeTQ_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  T? v;
}
''');
  }

  test_class_instanceField1_notFinal_typeVar_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  var v;
}
''');
  }

  test_class_instanceField1_notFinal_typeVoid_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void v;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
//    ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  final int v1;
  final int v2;
  this: v1 = 0;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration0_body2() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
  final int v1;
  final int v2;
  this: v1 = 0, v2 = 0;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v1) {
//    ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v1) {
  final int v1;
  final int v2;
  this : v2 = 0;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v1) {
//    ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  final int v1;
  final int v2;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration2_body0() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v1, this.v2) {
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration2_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A(this.v1, this.v2) {
  final int v1;
  final int v2;
}
''');
  }

  test_class_instanceField2_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v1;
  final int v2;
  A() {}
//^
// [diag.finalNotInitializedConstructor2] All final variables must be initialized, but 'v1' and 'v2' aren't.
}
''');
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int v1;
  int v2;
  this : v1 = 0, v1 = 0, v2 = 0, v2 = 0;
//               ^^
// [diag.fieldInitializedByMultipleInitializers] The field 'v1' can't be initialized twice in the same constructor.
//                               ^^
// [diag.fieldInitializedByMultipleInitializers] The field 'v2' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v1;
  int v2;
  A() : v1 = 0, v2 = 0 {}
}
''');
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int v1;
  int v2;
  A() : v1 = 0, v1 = 0, v2 = 0, v2 = 0 {}
//              ^^
// [diag.fieldInitializedByMultipleInitializers] The field 'v1' can't be initialized twice in the same constructor.
//                              ^^
// [diag.fieldInitializedByMultipleInitializers] The field 'v2' can't be initialized twice in the same constructor.
}
''');
  }

  test_class_instanceField3_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A() {
//    ^
// [diag.finalNotInitializedConstructor3Plus] All final variables must be initialized, but 'v1', 'v2', and 1 others aren't.
  final int v1;
  final int v2;
  final int v3;
}
''');
  }

  test_class_instanceField3_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int v1;
  final int v2;
  final int v3;
  A() {}
//^
// [diag.finalNotInitializedConstructor3Plus] All final variables must be initialized, but 'v1', 'v2', and 1 others aren't.
}
''');
  }

  test_class_instanceField3_notFinal_typeInt_noInitializer_secondaryConstructor_partiallyInitialized() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int v1, v2, v3;

  A() : v1 = 0, v3 = 0;
//^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'v2' must be initialized.
}
''');
  }

  test_class_staticField1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static const int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_class_staticField1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static const int v;
//                          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_class_staticField1_const_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int v = 0;
}
''');
  }

  test_class_staticField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_class_staticField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static final int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_class_staticField1_final_external_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static final int v;
}
''');
  }

  test_class_staticField1_final_late_hasInitializer_primaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class const A() {
  static late final int v = 0;
}
''');
  }

  test_class_staticField1_final_late_hasInitializer_secondaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static late final int v = 0;
  const A();
}
''');
  }

  test_class_staticField1_final_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_class_staticField1_final_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
  A();
}
''');
  }

  test_class_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static int v = 0;
//                    ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_class_staticField1_notFinal_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static int v;
}
''');
  }

  test_class_staticField1_notFinal_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static late int v;
}
''');
  }

  test_class_staticField1_notFinal_typeDynamic_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static dynamic v;
}
''');
  }

  test_class_staticField1_notFinal_typeFutureOrIntQ_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

class A {
  static FutureOr<int?> v;
}
''');
  }

  test_class_staticField1_notFinal_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static int v = 0;
}
''');
  }

  test_class_staticField1_notFinal_typeIntQ_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static int? v;
}
''');
  }

  test_class_staticField1_notFinal_typeNever_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static Never v;
//             ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
}
''');
  }

  test_class_staticField1_notFinal_typeVar_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static var v;
}
''');
  }

  test_class_staticField1_notFinal_typeVoid_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void v;
}
''');
  }

  test_class_staticField2_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static const int v1, v2;
//                 ^^
// [diag.constNotInitialized] The constant 'v1' must be initialized.
//                     ^^
// [diag.constNotInitialized] The constant 'v2' must be initialized.
}
''');
  }

  test_class_staticField3_final_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static final int v1 = 0, v2, v3 = 0;
//                         ^^
// [diag.finalNotInitialized] The final variable 'v2' must be initialized.
  A();
}
''');
  }

  test_class_staticField3_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static int v1 = 0, v2, v3 = 0;
//                   ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v2' must be initialized.
}
''');
  }

  test_class_staticField3_notFinal_typeInt_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static int v1 = 0, v2, v3 = 0;
//                   ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v2' must be initialized.
  A();
}
''');
  }

  test_classAbstract_instanceField1_final_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  final int v;
//          ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_classAbstract_instanceField1_notFinal_abstract_typeInt_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int v;
}
''');
  }

  test_classAbstract_instanceField1_notFinal_abstract_typeInt_noInitializer_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int v;
  A();
}
''');
  }

  test_enum_instanceField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  const int v;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
//          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_enum_instanceField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external final int v = 0;
//                   ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_enum_instanceField1_final_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external final int v;
}
''');
  }

  test_enum_instanceField1_final_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v = 0;
}
''');
  }

  test_enum_instanceField1_final_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v = 0;
  const A() : v = 0;
//            ^
// [diag.fieldInitializedInInitializerAndDeclaration] Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.
}
''');
  }

  test_enum_instanceField1_final_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e(0);
  final int v = 0;
  const A(this.v);
//             ^
// [diag.finalInitializedInDeclarationAndConstructor] 'v' is final and was given a value when it was declared, so it can't be set to a new value.
}
''');
  }

  test_enum_instanceField1_final_late_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_enum_instanceField1_final_late_hasInitializer_primaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
enum const A() {
  e;
  late final int v = 0;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_enum_instanceField1_final_late_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  late final int v;
//^^^^
// [diag.lateFinalFieldWithConstConstructor] Can't have a late final field in a class with a generative const constructor.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v;
//          ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
  e;
  final int v;
  this : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_body0() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
//   ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
  e;
  final int v;
  this;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
  e;
  final int v;
  this : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
//   ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
  e;
  final int v;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v) {
  e(0);
  final int v;
  this;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v) {
  e(0);
  final int v;
  this : v = 0;
//       ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_noDeclaration_body1() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v;
  this : v = 0;
//^^^^
// [diag.primaryConstructorBodyWithoutDeclaration] A primary constructor body requires a primary constructor declaration.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v;
  const A() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  e;
  final int v;
  const A() : v = 0, v = 0;
//                   ^
// [diag.fieldInitializedByMultipleInitializers] The field 'v' can't be initialized twice in the same constructor.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e(0);
  final int v;
  const A(this.v);
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  e(0);
  final int v;
  const A(this.v) : v = 0;
//                  ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  v1.zero(), v2.one();
  final int v;
  const A.zero() : v = 0;
  const A.one() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v;
  const A();
//      ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetInitialized() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  v1, v2._();
  final int v;
  const A() : this._();
  const A._() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetNotInitialized() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  v1, v2._();
  final int v;
  const A() : this._();
  const A._();
//      ^^^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
}
''');
  }

  test_enum_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  int v = 0;
//    ^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  const A() : v = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
//   ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  e;
  final int v1;
  final int v2;
  this: v1 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_body2() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
  e;
  final int v1;
  final int v2;
  this: v1 = 0, v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
//   ^
// [diag.finalNotInitializedConstructor2] All final variables must be initialized, but 'v1' and 'v2' aren't.
  e;
  final int v1;
  final int v2;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v1) {
//   ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  e(0);
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v1) {
  e(0);
  final int v1;
  final int v2;
  this : v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_noBody() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v1) {
//   ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v2' isn't.
  e(0);
  final int v1;
  final int v2;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration2_body0() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v1, this.v2) {
  e(0, 0);
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration2_noBody() async {
    await resolveTestCodeWithDiagnostics('''
enum A(this.v1, this.v2) {
  e(0, 0);
  final int v1;
  final int v2;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  e;
  final int v1;
  final int v2;
  const A() : v1 = 0, v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v1;
  final int v2;
  const A();
//      ^
// [diag.finalNotInitializedConstructor2] All final variables must be initialized, but 'v1' and 'v2' aren't.
}
''');
  }

  test_enum_instanceField3_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await resolveTestCodeWithDiagnostics('''
enum A() {
//   ^
// [diag.finalNotInitializedConstructor3Plus] All final variables must be initialized, but 'v1', 'v2', and 1 others aren't.
  e;
  final int v1;
  final int v2;
  final int v3;
}
''');
  }

  test_enum_instanceField3_final_noInitializer_secondaryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  final int v1;
  final int v2;
  final int v3;
  const A();
//      ^
// [diag.finalNotInitializedConstructor3Plus] All final variables must be initialized, but 'v1', 'v2', and 1 others aren't.
}
''');
  }

  test_enum_staticField1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static const int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_enum_staticField1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static const int v;
//                          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_enum_staticField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_enum_staticField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static final int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_enum_staticField1_final_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static final int v;
}
''');
  }

  test_enum_staticField1_final_late_hasInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static late final int v = 0;
}
''');
  }

  test_enum_staticField1_final_late_hasInitializer_primaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics('''
enum const A() {
  e;
  static late final int v = 0;
}
''');
  }

  test_enum_staticField1_final_noInitializer_noConstructor() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_enum_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static int v = 0;
//                    ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_enum_staticField1_notFinal_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  external static int v;
}
''');
  }

  test_enum_staticField1_notFinal_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static late int v;
}
''');
  }

  test_enum_staticField1_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static int v;
//           ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
}
''');
  }

  test_enum_staticField1_notFinal_typeVar_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
enum A {
  e;
  static var v;
}
''');
  }

  test_extension_instanceField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  const int v;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
//          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_extension_staticField1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static const int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extension_staticField1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static const int v;
//                          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_extension_staticField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  static const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_extension_staticField1_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static int v;
}
''');
  }

  test_extension_staticField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static final int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extension_staticField1_final_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static final int v;
}
''');
  }

  test_extension_staticField1_final_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  static final Object? v = 0;
}
''');
  }

  test_extension_staticField1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_extension_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  external static int v = 0;
//                    ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extension_staticField1_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {
  static int v;
//           ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
//             ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'v' isn't.
  final int v;
//          ^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named(this.it) : it = 0;
//                   ^^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  A.named();
//^^^^^^^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'it' isn't.
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  A.named() : it = 0;
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  A.named(this.it);
}
''');
  }

  test_extensionType_staticField1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static const int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extensionType_staticField1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static const int v;
//                          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_extensionType_staticField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_extensionType_staticField1_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static int v;
}
''');
  }

  test_extensionType_staticField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static final int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extensionType_staticField1_final_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static final int v;
}
''');
  }

  test_extensionType_staticField1_final_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static final Object? v = 0;
}
''');
  }

  test_extensionType_staticField1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_extensionType_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  external static int v = 0;
//                    ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_extensionType_staticField1_notFinal_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static late int v;
}
''');
  }

  test_extensionType_staticField1_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static int v;
//           ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
}
''');
  }

  test_localVariable1_const_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const int v = 0;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_localVariable1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const int v;
//          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_localVariable1_final_late_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  late final Object? v = 0;
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_localVariable1_final_late_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  late final Object? v;
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_localVariable1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  final Object? v;
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_localVariable2_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  const int v1, v2;
//          ^^
// [diag.constNotInitialized] The constant 'v1' must be initialized.
// [diag.unusedLocalVariable] The value of the local variable 'v1' isn't used.
//              ^^
// [diag.constNotInitialized] The constant 'v2' must be initialized.
// [diag.unusedLocalVariable] The value of the local variable 'v2' isn't used.
}
''');
  }

  test_mixin_instanceField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  const int v;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
//          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_mixin_instanceField1_final_abstract_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  abstract final int v;
}
''');
  }

  test_mixin_instanceField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external final int v = 0;
//                   ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_mixin_instanceField1_final_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external final int v;
}
''');
  }

  test_mixin_instanceField1_final_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  final int v = 0;
}
''');
  }

  test_mixin_instanceField1_final_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  late final int v;
}
''');
  }

  test_mixin_instanceField1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  final int v;
//          ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_mixin_instanceField1_notFinal_abstract_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  abstract int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external int v = 0;
//             ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_mixin_instanceField1_notFinal_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  late int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  int v;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'v' must be initialized.
}
''');
  }

  test_mixin_staticField1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static const int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_mixin_staticField1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static const int v;
//                          ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_mixin_staticField1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  static const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
}
''');
  }

  test_mixin_staticField1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static final int v = 0;
//                          ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_mixin_staticField1_final_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static final int v;
}
''');
  }

  test_mixin_staticField1_final_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  static final Object? v;
//                     ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
}
''');
  }

  test_mixin_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static int v = 0;
//                    ^
// [diag.externalFieldInitializer] External fields can't have initializers.
}
''');
  }

  test_mixin_staticField1_notFinal_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  external static int v;
}
''');
  }

  test_mixin_staticField1_notFinal_late_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  static late int v;
}
''');
  }

  test_mixin_staticField1_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  static int v;
//           ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
}
''');
  }

  test_topLevelVariable1_const_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external const int v = 0;
//                 ^
// [diag.externalVariableInitializer] External variables can't have initializers.
''');
  }

  test_topLevelVariable1_const_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external const int v;
//                 ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
''');
  }

  test_topLevelVariable1_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
const int v;
//        ^
// [diag.constNotInitialized] The constant 'v' must be initialized.
''');
  }

  test_topLevelVariable1_final_external_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external final int v = 0;
//                 ^
// [diag.externalVariableInitializer] External variables can't have initializers.
''');
  }

  test_topLevelVariable1_final_external_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external final int v;
''');
  }

  test_topLevelVariable1_final_noInitializer_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
final int v;
//        ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
''');
  }

  test_topLevelVariable1_final_noInitializer_nullable() async {
    await resolveTestCodeWithDiagnostics('''
final Object? v;
//            ^
// [diag.finalNotInitialized] The final variable 'v' must be initialized.
''');
  }

  test_topLevelVariable1_notFinal_external_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external int v = 0;
//           ^
// [diag.externalVariableInitializer] External variables can't have initializers.
''');
  }

  test_topLevelVariable1_notFinal_external_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
external int v;
''');
  }

  test_topLevelVariable1_notFinal_typeDynamic_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
dynamic v;
''');
  }

  test_topLevelVariable1_notFinal_typeFutureOrIntQ_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<int?> v;
''');
  }

  test_topLevelVariable1_notFinal_typeInt_hasInitializer() async {
    await resolveTestCodeWithDiagnostics('''
int v = 0;
''');
  }

  test_topLevelVariable1_notFinal_typeIntQ_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
int? v;
''');
  }

  test_topLevelVariable1_notFinal_typeNever_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
Never v;
//    ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v' must be initialized.
''');
  }

  test_topLevelVariable1_notFinal_typeVar_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
var v;
''');
  }

  test_topLevelVariable1_notFinal_typeVoid_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
void v;
''');
  }

  test_topLevelVariable2_const_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
const int v1, v2;
//        ^^
// [diag.constNotInitialized] The constant 'v1' must be initialized.
//            ^^
// [diag.constNotInitialized] The constant 'v2' must be initialized.
''');
  }

  test_topLevelVariable3_notFinal_typeInt_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
int v1 = 0, v2, v3 = 0;
//          ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v2' must be initialized.
''');
  }
}
