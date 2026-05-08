// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNotInitializedTest);
  });
}

@reflectiveTest
class VariableNotInitializedTest extends PubPackageResolutionTest {
  test_class_instanceField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  const int v;
}
''',
      [
        error(diag.constInstanceField, 12, 5),
        error(diag.constNotInitialized, 22, 1),
      ],
    );
  }

  test_class_instanceField1_final_abstract_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int v;
}
''');
  }

  test_class_instanceField1_final_abstract_noInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int v;
  A();
}
''');
  }

  test_class_instanceField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 31, 1)],
    );
  }

  test_class_instanceField1_final_external_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  external final int v;
}
''');
  }

  test_class_instanceField1_final_external_noInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  external final int v;
  A();
}
''');
  }

  test_class_instanceField1_final_functionTypedFieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final Function v;
  A(int this.v()) {}
}
''');
  }

  test_class_instanceField1_final_hasInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  final Object? v = 0;
}
''');
  }

  test_class_instanceField1_final_hasInitializer_primaryConstructor_constructorInitializer() async {
    await assertErrorsInCode(
      '''
class A() {
  final int v = 0;
  this : v = 0;
}
''',
      [
        error(
          diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor,
          40,
          1,
        ),
      ],
    );
  }

  test_class_instanceField1_final_hasInitializer_primaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
class A(this.v) {
  final int v = 0;
}
''',
      [
        error(
          diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor,
          13,
          1,
        ),
      ],
    );
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  final Object? v = 0;
  A();
}
''');
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  final int v = 0;
  A() : v = 0;
}
''',
      [error(diag.fieldInitializedInInitializerAndDeclaration, 37, 1)],
    );
  }

  test_class_instanceField1_final_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
class A {
  final int v = 0;
  A(this.v) {}
}
''',
      [error(diag.finalInitializedInDeclarationAndConstructor, 38, 1)],
    );
  }

  test_class_instanceField1_final_late_hasInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  late final int v = 0;
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor() async {
    await assertNoErrorsInCode('''
class A() {
  late final int v = 0;
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor_const() async {
    await assertErrorsInCode(
      '''
class const A() {
  late final int v = 0;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 20, 4)],
    );
  }

  test_class_instanceField1_final_late_hasInitializer_primaryConstructor_const_hasNotConst() async {
    await assertErrorsInCode(
      '''
class const A() {
  late final int v = 0;
  A.notConst() : this();
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 20, 4)],
    );
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  late final int v = 0;
  A();
}
''');
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor_const() async {
    await assertErrorsInCode(
      '''
class A {
  late final int v = 0;
  const A();
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 12, 4)],
    );
  }

  test_class_instanceField1_final_late_hasInitializer_secondaryConstructor_const_hasNotConst() async {
    await assertErrorsInCode(
      '''
class A {
  late final int v = 0;
  const A();
  A.notConst();
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 12, 4)],
    );
  }

  test_class_instanceField1_final_late_noInitializer_factoryConstructor_const() async {
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode('''
class A {
  late final Object? v;
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_primaryConstructor_const() async {
    await assertErrorsInCode(
      '''
class const A() {
  late final int v;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 20, 4)],
    );
  }

  test_class_instanceField1_final_late_noInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  late final Object? v;
  A();
}
''');
  }

  test_class_instanceField1_final_late_noInitializer_secondaryConstructor_const() async {
    await assertErrorsInCode(
      '''
class A {
  late final int v;
  const A();
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 12, 4)],
    );
  }

  test_class_instanceField1_final_noInitializer_factoryConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  final int v;

  factory A() => throw 0;
}
''',
      [error(diag.finalNotInitialized, 22, 1)],
    );
  }

  test_class_instanceField1_final_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  final Object? v;
}
''',
      [error(diag.finalNotInitialized, 26, 1)],
    );
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A() {
  final int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_body0() async {
    await assertErrorsInCode(
      '''
class A() {
  final int v;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await assertNoErrorsInCode('''
class A() {
  final int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
class A() {
  final int v;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await assertNoErrorsInCode('''
class A(this.v) {
  final int v;
  this;
}
''');
  }

  test_class_instanceField1_final_noInitializer_primaryConstructor_noDeclaration_body1() async {
    await assertErrorsInCode(
      '''
class A {
  final int v;
  this : v = 0;
}
''',
      [error(diag.primaryConstructorBodyWithoutDeclaration, 27, 4)],
    );
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A {
  final Object? v;
  A() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class A {
  final Object? v;
  A(this.v);
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_named() async {
    await assertErrorsInCode(
      '''
class A {
  final int v;
  A.named() {}
}
''',
      [error(diag.finalNotInitializedConstructor1, 27, 7)],
    );
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A {
  final int v;
  A.zero() : v = 0;
  A.one() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
class A {
  final int v;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor1, 27, 1)],
    );
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_duplicateField() async {
    await assertErrorsInCode(
      '''
class A {
  A();
  final int v;
  final int v;
}
''',
      [
        error(
          diag.duplicateDefinition,
          44,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetInitialized() async {
    await assertNoErrorsInCode('''
class A {
  final int v;
  A() : this._();
  A._() : v = 0;
}
''');
  }

  test_class_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetNotInitialized() async {
    await assertErrorsInCode(
      '''
class A {
  final int v;
  A() : this._();
  A._();
}
''',
      [error(diag.finalNotInitializedConstructor1, 45, 3)],
    );
  }

  test_class_instanceField1_notFinal_abstract_typeInt_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  abstract int v;
}
''',
      [error(diag.concreteClassWithAbstractMember, 12, 15)],
    );
  }

  test_class_instanceField1_notFinal_external_typeDouble_noInitializer_struct() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';

final class A extends Struct {
  @Double()
  external double v;
}
''');
  }

  test_class_instanceField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 25, 1)],
    );
  }

  test_class_instanceField1_notFinal_external_typeInt_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  external int v;
}
''');
  }

  test_class_instanceField1_notFinal_external_typeInt_noInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  external int v;
  A();
}
''');
  }

  test_class_instanceField1_notFinal_late_typeInt_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  late int v;
}
''');
  }

  test_class_instanceField1_notFinal_typeDynamic_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  dynamic v;
}
''');
  }

  test_class_instanceField1_notFinal_typeFutureOrIntQ_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A {
  FutureOr<int?> v;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_factoryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  int v = 0;

  A(this.v);

  factory A.named() => A(0);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  int v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_constructorInitializer() async {
    await assertErrorsInCode(
      '''
class A() {
  int v = 0;
  this : v = 0;
}
''',
      [
        error(
          diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor,
          34,
          1,
        ),
      ],
    );
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
class A(this.v) {
  int v = 0;
}
''',
      [
        error(
          diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor,
          13,
          1,
        ),
      ],
    );
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_primaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await assertErrorsInCode(
      r'''
class A(this.v) {
  int v = 0;
  this : v = 0;
}
''',
      [
        error(
          diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor,
          13,
          1,
        ),
        error(diag.fieldInitializedInParameterAndInitializer, 40, 1),
      ],
    );
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A {
  int v = 0;
  A() : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
class A {
  int v = 0;
  A() : v = 0, v = 0 {}
}
''',
      [error(diag.fieldInitializedByMultipleInitializers, 38, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class A {
  int v = 0;
  A(this.v);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  int v = 0;
  A(this.v) : v = 0 {}
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 37, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_factoryConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  int v;

  factory A() => throw 0;
}
''',
      [error(diag.notInitializedNonNullableInstanceField, 16, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_noConstructor_inferred() async {
    await assertErrorsInCode(
      '''
abstract class A {
  int get v;
}

class B extends A {
  var v;
}
''',
      [error(diag.notInitializedNonNullableInstanceField, 61, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_bodyWithoutDeclaration() async {
    await assertErrorsInCode(
      '''
class A {
  int v;
  this : v = 0;
}
''',
      [error(diag.primaryConstructorBodyWithoutDeclaration, 21, 4)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A() {
  int v;
  this : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
class A() {
  int v;
  this : v = 0, v = 0;
}
''',
      [error(diag.fieldInitializedByMultipleInitializers, 37, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer3() async {
    await assertErrorsInCode(
      r'''
class A() {
  int v;
  this : v = 0, v = 0, v = 0;
}
''',
      [
        error(diag.fieldInitializedByMultipleInitializers, 37, 1),
        error(diag.fieldInitializedByMultipleInitializers, 44, 1),
      ],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class A {
  int v;

  A() : v = 0;
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
class A {
  int v;
  A() : v = 0, v = 0 {}
}
''',
      [error(diag.fieldInitializedByMultipleInitializers, 34, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer3() async {
    await assertErrorsInCode(
      r'''
class A {
  int v;
  A() : v = 0, v = 0, v = 0 {}
}
''',
      [
        error(diag.fieldInitializedByMultipleInitializers, 34, 1),
        error(diag.fieldInitializedByMultipleInitializers, 41, 1),
      ],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class A {
  int v;

  A(this.v);
}
''');
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  int v;
  A(this.v) : v = 0 {}
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 33, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeInt_noInitializer_secondaryConstructors_notInitializedByAll() async {
    await assertErrorsInCode(
      '''
class A {
  int v;

  A.foo(this.v);

  A.bar();
}
''',
      [error(diag.notInitializedNonNullableInstanceFieldConstructor, 40, 5)],
    );
  }

  test_class_instanceField1_notFinal_typeIntQ_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  int? v;
}
''');
  }

  test_class_instanceField1_notFinal_typeNever_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  Never v;
}
''',
      [error(diag.notInitializedNonNullableInstanceField, 18, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeT_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
class A<T> {
  T v;
}
''',
      [error(diag.notInitializedNonNullableInstanceField, 17, 1)],
    );
  }

  test_class_instanceField1_notFinal_typeTQ_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A<T> {
  T? v;
}
''');
  }

  test_class_instanceField1_notFinal_typeVar_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  var v;
}
''');
  }

  test_class_instanceField1_notFinal_typeVoid_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  void v;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await assertErrorsInCode(
      '''
class A() {
  final int v1;
  final int v2;
  this: v1 = 0;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration0_body2() async {
    await assertNoErrorsInCode('''
class A() {
  final int v1;
  final int v2;
  this: v1 = 0, v2 = 0;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await assertErrorsInCode(
      '''
class A(this.v1) {
  final int v1;
  final int v2;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await assertNoErrorsInCode('''
class A(this.v1) {
  final int v1;
  final int v2;
  this : v2 = 0;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration1_noBody() async {
    await assertErrorsInCode(
      '''
class A(this.v1) {
  final int v1;
  final int v2;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration2_body0() async {
    await assertNoErrorsInCode('''
class A(this.v1, this.v2) {
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_class_instanceField2_final_noInitializer_primaryConstructor_declaration2_noBody() async {
    await assertNoErrorsInCode('''
class A(this.v1, this.v2) {
  final int v1;
  final int v2;
}
''');
  }

  test_class_instanceField2_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
class A {
  final int v1;
  final int v2;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor2, 44, 1)],
    );
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_primaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
class A() {
  int v1;
  int v2;
  this : v1 = 0, v1 = 0, v2 = 0, v2 = 0;
}
''',
      [
        error(diag.fieldInitializedByMultipleInitializers, 49, 2),
        error(diag.fieldInitializedByMultipleInitializers, 65, 2),
      ],
    );
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  int v1;
  int v2;
  A() : v1 = 0, v2 = 0 {}
}
''');
  }

  test_class_instanceField2_notFinal_typeInt_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
class A {
  int v1;
  int v2;
  A() : v1 = 0, v1 = 0, v2 = 0, v2 = 0 {}
}
''',
      [
        error(diag.fieldInitializedByMultipleInitializers, 46, 2),
        error(diag.fieldInitializedByMultipleInitializers, 62, 2),
      ],
    );
  }

  test_class_instanceField3_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
class A() {
  final int v1;
  final int v2;
  final int v3;
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 6, 1)],
    );
  }

  test_class_instanceField3_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
class A {
  final int v1;
  final int v2;
  final int v3;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 60, 1)],
    );
  }

  test_class_instanceField3_notFinal_typeInt_noInitializer_secondaryConstructor_partiallyInitialized() async {
    await assertErrorsInCode(
      '''
class A {
  int v1, v2, v3;

  A() : v1 = 0, v3 = 0;
}
''',
      [error(diag.notInitializedNonNullableInstanceFieldConstructor, 31, 1)],
    );
  }

  test_class_staticField1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external static const int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 38, 1)],
    );
  }

  test_class_staticField1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external static const int v;
}
''',
      [error(diag.constNotInitialized, 38, 1)],
    );
  }

  test_class_staticField1_const_hasInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int v = 0;
}
''');
  }

  test_class_staticField1_const_noInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  static const int v;
}
''',
      [error(diag.constNotInitialized, 29, 1)],
    );
  }

  test_class_staticField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external static final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 38, 1)],
    );
  }

  test_class_staticField1_final_external_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
class A {
  external static final int v;
}
''');
  }

  test_class_staticField1_final_late_hasInitializer_primaryConstructor_const() async {
    await assertNoErrorsInCode('''
class const A() {
  static late final int v = 0;
}
''');
  }

  test_class_staticField1_final_late_hasInitializer_secondaryConstructor_const() async {
    await assertNoErrorsInCode('''
class A {
  static late final int v = 0;
  const A();
}
''');
  }

  test_class_staticField1_final_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  static final Object? v;
}
''',
      [error(diag.finalNotInitialized, 33, 1)],
    );
  }

  test_class_staticField1_final_noInitializer_secondaryConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  static final Object? v;
  A();
}
''',
      [error(diag.finalNotInitialized, 33, 1)],
    );
  }

  test_class_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  external static int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 32, 1)],
    );
  }

  test_class_staticField1_notFinal_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  external static int v;
}
''');
  }

  test_class_staticField1_notFinal_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static late int v;
}
''');
  }

  test_class_staticField1_notFinal_typeDynamic_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static dynamic v;
}
''');
  }

  test_class_staticField1_notFinal_typeFutureOrIntQ_noInitializer() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A {
  static FutureOr<int?> v;
}
''');
  }

  test_class_staticField1_notFinal_typeInt_hasInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static int v = 0;
}
''');
  }

  test_class_staticField1_notFinal_typeIntQ_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static int? v;
}
''');
  }

  test_class_staticField1_notFinal_typeNever_noInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  static Never v;
}
''',
      [error(diag.notInitializedNonNullableVariable, 25, 1)],
    );
  }

  test_class_staticField1_notFinal_typeVar_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static var v;
}
''');
  }

  test_class_staticField1_notFinal_typeVoid_noInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static void v;
}
''');
  }

  test_class_staticField2_const_noInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  static const int v1, v2;
}
''',
      [
        error(diag.constNotInitialized, 29, 2),
        error(diag.constNotInitialized, 33, 2),
      ],
    );
  }

  test_class_staticField3_final_noInitializer_secondaryConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  static final int v1 = 0, v2, v3 = 0;
  A();
}
''',
      [error(diag.finalNotInitialized, 37, 2)],
    );
  }

  test_class_staticField3_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  static int v1 = 0, v2, v3 = 0;
}
''',
      [error(diag.notInitializedNonNullableVariable, 31, 2)],
    );
  }

  test_class_staticField3_notFinal_typeInt_noInitializer_secondaryConstructor() async {
    await assertErrorsInCode(
      '''
class A {
  static int v1 = 0, v2, v3 = 0;
  A();
}
''',
      [error(diag.notInitializedNonNullableVariable, 31, 2)],
    );
  }

  test_classAbstract_instanceField1_final_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
abstract class A {
  final int v;
}
''',
      [error(diag.finalNotInitialized, 31, 1)],
    );
  }

  test_classAbstract_instanceField1_notFinal_abstract_typeInt_noInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int v;
}
''');
  }

  test_classAbstract_instanceField1_notFinal_abstract_typeInt_noInitializer_secondaryConstructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int v;
  A();
}
''');
  }

  test_enum_instanceField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  const int v;
}
''',
      [
        error(diag.constInstanceField, 16, 5),
        error(diag.constNotInitialized, 26, 1),
        error(diag.nonFinalFieldInEnum, 26, 1),
      ],
    );
  }

  test_enum_instanceField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  external final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 35, 1)],
    );
  }

  test_enum_instanceField1_final_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  external final int v;
}
''');
  }

  test_enum_instanceField1_final_hasInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  final int v = 0;
}
''');
  }

  test_enum_instanceField1_final_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v = 0;
  const A() : v = 0;
}
''',
      [error(diag.fieldInitializedInInitializerAndDeclaration, 47, 1)],
    );
  }

  test_enum_instanceField1_final_hasInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
enum A {
  e(0);
  final int v = 0;
  const A(this.v);
}
''',
      [error(diag.finalInitializedInDeclarationAndConstructor, 51, 1)],
    );
  }

  test_enum_instanceField1_final_late_hasInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  late final int v = 0;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 16, 4)],
    );
  }

  test_enum_instanceField1_final_late_hasInitializer_primaryConstructor_const() async {
    await assertErrorsInCode(
      '''
enum const A() {
  e;
  late final int v = 0;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 24, 4)],
    );
  }

  test_enum_instanceField1_final_late_noInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  late final int v;
}
''',
      [error(diag.lateFinalFieldWithConstConstructor, 16, 4)],
    );
  }

  test_enum_instanceField1_final_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v;
}
''',
      [error(diag.finalNotInitialized, 26, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
enum A() {
  e;
  final int v;
  this : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_body0() async {
    await assertErrorsInCode(
      '''
enum A() {
  e;
  final int v;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await assertNoErrorsInCode('''
enum A() {
  e;
  final int v;
  this : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum A() {
  e;
  final int v;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await assertNoErrorsInCode('''
enum A(this.v) {
  e(0);
  final int v;
  this;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await assertErrorsInCode(
      '''
enum A(this.v) {
  e(0);
  final int v;
  this : v = 0;
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 49, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_primaryConstructor_noDeclaration_body1() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v;
  this : v = 0;
}
''',
      [error(diag.primaryConstructorBodyWithoutDeclaration, 31, 4)],
    );
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  final int v;
  const A() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_constructorInitializer2() async {
    await assertErrorsInCode(
      r'''
enum A {
  e;
  final int v;
  const A() : v = 0, v = 0;
}
''',
      [error(diag.fieldInitializedByMultipleInitializers, 50, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
enum A {
  e(0);
  final int v;
  const A(this.v);
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await assertErrorsInCode(
      r'''
enum A {
  e(0);
  final int v;
  const A(this.v) : v = 0;
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 52, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  v1.zero(), v2.one();
  final int v;
  const A.zero() : v = 0;
  const A.one() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v;
  const A();
}
''',
      [error(diag.finalNotInitializedConstructor1, 37, 1)],
    );
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetInitialized() async {
    await assertNoErrorsInCode('''
enum A {
  v1, v2._();
  final int v;
  const A() : this._();
  const A._() : v = 0;
}
''');
  }

  test_enum_instanceField1_final_noInitializer_secondaryConstructor_unnamed_redirecting_targetNotInitialized() async {
    await assertErrorsInCode(
      '''
enum A {
  v1, v2._();
  final int v;
  const A() : this._();
  const A._();
}
''',
      [error(diag.finalNotInitializedConstructor1, 70, 3)],
    );
  }

  test_enum_instanceField1_notFinal_typeInt_hasInitializer_secondaryConstructor_constructorInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  int v = 0;
  const A() : v = 0;
}
''',
      [error(diag.nonFinalFieldInEnum, 20, 1)],
    );
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_body1() async {
    await assertErrorsInCode(
      '''
enum A() {
  e;
  final int v1;
  final int v2;
  this: v1 = 0;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_body2() async {
    await assertNoErrorsInCode('''
enum A() {
  e;
  final int v1;
  final int v2;
  this: v1 = 0, v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum A() {
  e;
  final int v1;
  final int v2;
}
''',
      [error(diag.finalNotInitializedConstructor2, 5, 1)],
    );
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_body0() async {
    await assertErrorsInCode(
      '''
enum A(this.v1) {
  e(0);
  final int v1;
  final int v2;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_body1() async {
    await assertNoErrorsInCode('''
enum A(this.v1) {
  e(0);
  final int v1;
  final int v2;
  this : v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration1_noBody() async {
    await assertErrorsInCode(
      '''
enum A(this.v1) {
  e(0);
  final int v1;
  final int v2;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration2_body0() async {
    await assertNoErrorsInCode('''
enum A(this.v1, this.v2) {
  e(0, 0);
  final int v1;
  final int v2;
  this;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_primaryConstructor_declaration2_noBody() async {
    await assertNoErrorsInCode('''
enum A(this.v1, this.v2) {
  e(0, 0);
  final int v1;
  final int v2;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_secondaryConstructor_constructorInitializer() async {
    await assertNoErrorsInCode(r'''
enum A {
  e;
  final int v1;
  final int v2;
  const A() : v1 = 0, v2 = 0;
}
''');
  }

  test_enum_instanceField2_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v1;
  final int v2;
  const A();
}
''',
      [error(diag.finalNotInitializedConstructor2, 54, 1)],
    );
  }

  test_enum_instanceField3_final_noInitializer_primaryConstructor_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum A() {
  e;
  final int v1;
  final int v2;
  final int v3;
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 5, 1)],
    );
  }

  test_enum_instanceField3_final_noInitializer_secondaryConstructor_unnamed() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  final int v1;
  final int v2;
  final int v3;
  const A();
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 70, 1)],
    );
  }

  test_enum_staticField1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  external static const int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 42, 1)],
    );
  }

  test_enum_staticField1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  external static const int v;
}
''',
      [error(diag.constNotInitialized, 42, 1)],
    );
  }

  test_enum_staticField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  static const int v;
}
''',
      [error(diag.constNotInitialized, 33, 1)],
    );
  }

  test_enum_staticField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  external static final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 42, 1)],
    );
  }

  test_enum_staticField1_final_external_noInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  external static final int v;
}
''');
  }

  test_enum_staticField1_final_late_hasInitializer_noConstructor() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  static late final int v = 0;
}
''');
  }

  test_enum_staticField1_final_late_hasInitializer_primaryConstructor_const() async {
    await assertNoErrorsInCode('''
enum const A() {
  e;
  static late final int v = 0;
}
''');
  }

  test_enum_staticField1_final_noInitializer_noConstructor() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  static final Object? v;
}
''',
      [error(diag.finalNotInitialized, 37, 1)],
    );
  }

  test_enum_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  external static int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 36, 1)],
    );
  }

  test_enum_staticField1_notFinal_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  external static int v;
}
''');
  }

  test_enum_staticField1_notFinal_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  static late int v;
}
''');
  }

  test_enum_staticField1_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
enum A {
  e;
  static int v;
}
''',
      [error(diag.notInitializedNonNullableVariable, 27, 1)],
    );
  }

  test_enum_staticField1_notFinal_typeVar_noInitializer() async {
    await assertNoErrorsInCode('''
enum A {
  e;
  static var v;
}
''');
  }

  test_extension_instanceField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  const int v;
}
''',
      [
        error(diag.constInstanceField, 23, 5),
        error(diag.extensionDeclaresInstanceField, 33, 1),
        error(diag.constNotInitialized, 33, 1),
      ],
    );
  }

  test_extension_staticField1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  external static const int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 49, 1)],
    );
  }

  test_extension_staticField1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  external static const int v;
}
''',
      [error(diag.constNotInitialized, 49, 1)],
    );
  }

  test_extension_staticField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  static const int v;
}
''',
      [error(diag.constNotInitialized, 40, 1)],
    );
  }

  test_extension_staticField1_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
extension A on int {
  external static int v;
}
''');
  }

  test_extension_staticField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  external static final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 49, 1)],
    );
  }

  test_extension_staticField1_final_external_noInitializer() async {
    await assertNoErrorsInCode('''
extension A on int {
  external static final int v;
}
''');
  }

  test_extension_staticField1_final_hasInitializer() async {
    await assertNoErrorsInCode('''
extension A on int {
  static final Object? v = 0;
}
''');
  }

  test_extension_staticField1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  static final Object? v;
}
''',
      [error(diag.finalNotInitialized, 44, 1)],
    );
  }

  test_extension_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  external static int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 43, 1)],
    );
  }

  test_extension_staticField1_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
extension A on int {
  static int v;
}
''',
      [error(diag.notInitializedNonNullableVariable, 34, 1)],
    );
  }

  test_extensionType_instanceField1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  final int v;
}
''',
      [
        error(diag.finalNotInitializedConstructor1, 15, 1),
        error(diag.extensionTypeDeclaresInstanceField, 39, 1),
      ],
    );
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_fieldFormalParameter_constructorInitializer() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  A.named(this.it) : it = 0;
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 48, 2)],
    );
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  A.named();
}
''',
      [error(diag.finalNotInitializedConstructor1, 29, 7)],
    );
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named_constructorInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named() : it = 0;
}
''');
  }

  test_extensionType_instanceField1_final_noInitializer_secondaryConstructor_named_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named(this.it);
}
''');
  }

  test_extensionType_staticField1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  external static const int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 55, 1)],
    );
  }

  test_extensionType_staticField1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  external static const int v;
}
''',
      [error(diag.constNotInitialized, 55, 1)],
    );
  }

  test_extensionType_staticField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  static const int v;
}
''',
      [error(diag.constNotInitialized, 46, 1)],
    );
  }

  test_extensionType_staticField1_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  external static int v;
}
''');
  }

  test_extensionType_staticField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  external static final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 55, 1)],
    );
  }

  test_extensionType_staticField1_final_external_noInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  external static final int v;
}
''');
  }

  test_extensionType_staticField1_final_hasInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  static final Object? v = 0;
}
''');
  }

  test_extensionType_staticField1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  static final Object? v;
}
''',
      [error(diag.finalNotInitialized, 50, 1)],
    );
  }

  test_extensionType_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  external static int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 49, 1)],
    );
  }

  test_extensionType_staticField1_notFinal_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  static late int v;
}
''');
  }

  test_extensionType_staticField1_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  static int v;
}
''',
      [error(diag.notInitializedNonNullableVariable, 40, 1)],
    );
  }

  test_localVariable1_const_hasInitializer() async {
    await assertErrorsInCode(
      r'''
void f() {
  const int v = 0;
}
''',
      [error(diag.unusedLocalVariable, 23, 1)],
    );
  }

  test_localVariable1_const_noInitializer() async {
    await assertErrorsInCode(
      r'''
void f() {
  const int v;
}
''',
      [
        error(diag.unusedLocalVariable, 23, 1),
        error(diag.constNotInitialized, 23, 1),
      ],
    );
  }

  test_localVariable1_final_late_hasInitializer() async {
    await assertErrorsInCode(
      '''
void f() {
  late final Object? v = 0;
}
''',
      [error(diag.unusedLocalVariable, 32, 1)],
    );
  }

  test_localVariable1_final_late_noInitializer() async {
    await assertErrorsInCode(
      '''
void f() {
  late final Object? v;
}
''',
      [error(diag.unusedLocalVariable, 32, 1)],
    );
  }

  test_localVariable1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
void f() {
  final Object? v;
}
''',
      [error(diag.unusedLocalVariable, 27, 1)],
    );
  }

  test_localVariable2_const_noInitializer() async {
    await assertErrorsInCode(
      '''
void f() {
  const int v1, v2;
}
''',
      [
        error(diag.unusedLocalVariable, 23, 2),
        error(diag.constNotInitialized, 23, 2),
        error(diag.unusedLocalVariable, 27, 2),
        error(diag.constNotInitialized, 27, 2),
      ],
    );
  }

  test_mixin_instanceField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  const int v;
}
''',
      [
        error(diag.constInstanceField, 12, 5),
        error(diag.constNotInitialized, 22, 1),
      ],
    );
  }

  test_mixin_instanceField1_final_abstract_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  abstract final int v;
}
''');
  }

  test_mixin_instanceField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 31, 1)],
    );
  }

  test_mixin_instanceField1_final_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  external final int v;
}
''');
  }

  test_mixin_instanceField1_final_hasInitializer() async {
    await assertNoErrorsInCode(r'''
mixin A {
  final int v = 0;
}
''');
  }

  test_mixin_instanceField1_final_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  late final int v;
}
''');
  }

  test_mixin_instanceField1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  final int v;
}
''',
      [error(diag.finalNotInitialized, 22, 1)],
    );
  }

  test_mixin_instanceField1_notFinal_abstract_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  abstract int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 25, 1)],
    );
  }

  test_mixin_instanceField1_notFinal_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  external int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  late int v;
}
''');
  }

  test_mixin_instanceField1_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  int v;
}
''',
      [error(diag.notInitializedNonNullableInstanceField, 16, 1)],
    );
  }

  test_mixin_staticField1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external static const int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 38, 1)],
    );
  }

  test_mixin_staticField1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external static const int v;
}
''',
      [error(diag.constNotInitialized, 38, 1)],
    );
  }

  test_mixin_staticField1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  static const int v;
}
''',
      [error(diag.constNotInitialized, 29, 1)],
    );
  }

  test_mixin_staticField1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external static final int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 38, 1)],
    );
  }

  test_mixin_staticField1_final_external_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  external static final int v;
}
''');
  }

  test_mixin_staticField1_final_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  static final Object? v;
}
''',
      [error(diag.finalNotInitialized, 33, 1)],
    );
  }

  test_mixin_staticField1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  external static int v = 0;
}
''',
      [error(diag.externalFieldInitializer, 32, 1)],
    );
  }

  test_mixin_staticField1_notFinal_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  external static int v;
}
''');
  }

  test_mixin_staticField1_notFinal_late_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
mixin A {
  static late int v;
}
''');
  }

  test_mixin_staticField1_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
mixin A {
  static int v;
}
''',
      [error(diag.notInitializedNonNullableVariable, 23, 1)],
    );
  }

  test_topLevelVariable1_const_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
external const int v = 0;
''',
      [error(diag.externalVariableInitializer, 19, 1)],
    );
  }

  test_topLevelVariable1_const_external_noInitializer() async {
    await assertErrorsInCode(
      '''
external const int v;
''',
      [error(diag.constNotInitialized, 19, 1)],
    );
  }

  test_topLevelVariable1_const_noInitializer() async {
    await assertErrorsInCode(
      '''
const int v;
''',
      [error(diag.constNotInitialized, 10, 1)],
    );
  }

  test_topLevelVariable1_final_external_hasInitializer() async {
    await assertErrorsInCode(
      '''
external final int v = 0;
''',
      [error(diag.externalVariableInitializer, 19, 1)],
    );
  }

  test_topLevelVariable1_final_external_noInitializer() async {
    await assertNoErrorsInCode('''
external final int v;
''');
  }

  test_topLevelVariable1_final_noInitializer_nonNullable() async {
    await assertErrorsInCode(
      '''
final int v;
''',
      [error(diag.finalNotInitialized, 10, 1)],
    );
  }

  test_topLevelVariable1_final_noInitializer_nullable() async {
    await assertErrorsInCode(
      '''
final Object? v;
''',
      [error(diag.finalNotInitialized, 14, 1)],
    );
  }

  test_topLevelVariable1_notFinal_external_typeInt_hasInitializer() async {
    await assertErrorsInCode(
      '''
external int v = 0;
''',
      [error(diag.externalVariableInitializer, 13, 1)],
    );
  }

  test_topLevelVariable1_notFinal_external_typeInt_noInitializer() async {
    await assertNoErrorsInCode('''
external int v;
''');
  }

  test_topLevelVariable1_notFinal_typeDynamic_noInitializer() async {
    await assertNoErrorsInCode('''
dynamic v;
''');
  }

  test_topLevelVariable1_notFinal_typeFutureOrIntQ_noInitializer() async {
    await assertNoErrorsInCode('''
import 'dart:async';

FutureOr<int?> v;
''');
  }

  test_topLevelVariable1_notFinal_typeInt_hasInitializer() async {
    await assertNoErrorsInCode('''
int v = 0;
''');
  }

  test_topLevelVariable1_notFinal_typeIntQ_noInitializer() async {
    await assertNoErrorsInCode('''
int? v;
''');
  }

  test_topLevelVariable1_notFinal_typeNever_noInitializer() async {
    await assertErrorsInCode(
      '''
Never v;
''',
      [error(diag.notInitializedNonNullableVariable, 6, 1)],
    );
  }

  test_topLevelVariable1_notFinal_typeVar_noInitializer() async {
    await assertNoErrorsInCode('''
var v;
''');
  }

  test_topLevelVariable1_notFinal_typeVoid_noInitializer() async {
    await assertNoErrorsInCode('''
void v;
''');
  }

  test_topLevelVariable2_const_noInitializer() async {
    await assertErrorsInCode(
      '''
const int v1, v2;
''',
      [
        error(diag.constNotInitialized, 10, 2),
        error(diag.constNotInitialized, 14, 2),
      ],
    );
  }

  test_topLevelVariable3_notFinal_typeInt_noInitializer() async {
    await assertErrorsInCode(
      '''
int v1 = 0, v2, v3 = 0;
''',
      [error(diag.notInitializedNonNullableVariable, 12, 2)],
    );
  }
}
