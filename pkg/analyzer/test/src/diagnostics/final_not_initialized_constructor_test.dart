// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalNotInitializedConstructorTest);
  });
}

@reflectiveTest
class FinalNotInitializedConstructorTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsSecondaryConstructor_unnamed_1of1() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f;
  A();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f = 0;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsSecondaryConstructor_unnamed_1of2() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f1;
  final int f2;
  A();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f1 = 0;
}
''');

    await resolveFile2(testFile);
    assertErrorsInResult([
      error(
        diag.finalNotInitializedConstructor1,
        60,
        1,
        messageContains: ['f2'],
      ),
    ]);

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsSecondaryConstructor_unnamed_2of2() async {
    newFile(testFile.path, r'''
part 'a.dart';
part 'b.dart';

class A {
  final int f1;
  final int f2;
  A();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f1 = 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f2 = 0;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsSecondaryConstructor_unnamed_noInitializers() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f;
  A() : f = 0;
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_declaresSecondaryConstructor_unnamed_noInitializers() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f;
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  A();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([error(diag.finalNotInitializedConstructor1, 42, 1)]);
  }

  test_class_field_primaryConstructor_fields1_declaration0_body0() async {
    await assertErrorsInCode(
      '''
class C() {
  final int f;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_field_primaryConstructor_fields1_declaration0_body1() async {
    await assertNoErrorsInCode('''
class C() {
  final int f;
  this : f = 2;
}
''');
  }

  test_class_field_primaryConstructor_fields1_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
class C() {
  final int f;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_field_primaryConstructor_fields1_declaration1_body0() async {
    await assertNoErrorsInCode('''
class C(this.f) {
  final int f;
  this;
}
''');
  }

  test_class_field_primaryConstructor_fields1_noDeclaration_body1() async {
    await assertErrorsInCode(
      '''
class C {
  final int f;
  this : f = 0;
}
''',
      [
        error(diag.finalNotInitialized, 22, 1),
        error(diag.primaryConstructorBodyWithoutDeclaration, 27, 13),
      ],
    );
  }

  test_class_field_primaryConstructor_fields2_declaration0_body1() async {
    await assertErrorsInCode(
      '''
class C() {
  final int f1;
  final int f2;
  this: f1 = 0;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_field_primaryConstructor_fields2_declaration0_body2() async {
    await assertNoErrorsInCode('''
class C() {
  final int f1;
  final int f2;
  this: f1 = 0, f2 = 0;
}
''');
  }

  test_class_field_primaryConstructor_fields2_declaration1_body0() async {
    await assertErrorsInCode(
      '''
class C(this.f1) {
  final int f1;
  final int f2;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_field_primaryConstructor_fields2_declaration1_body1() async {
    await assertNoErrorsInCode('''
class C(this.f1) {
  final int f1;
  final int f2;
  this : f2 = 0;
}
''');
  }

  test_class_field_primaryConstructor_fields2_declaration1_noBody() async {
    await assertErrorsInCode(
      '''
class C(this.f1) {
  final int f1;
  final int f2;
}
''',
      [error(diag.finalNotInitializedConstructor1, 6, 1)],
    );
  }

  test_class_field_primaryConstructor_fields2_declaration2_body0() async {
    await assertNoErrorsInCode('''
class C(this.f1, this.f2) {
  final int f1;
  final int f2;
  this;
}
''');
  }

  test_class_field_primaryConstructor_fields2_declaration2_noBody() async {
    await assertNoErrorsInCode('''
class C(this.f1, this.f2) {
  final int f1;
  final int f2;
}
''');
  }

  test_class_field_primaryConstructor_fields3_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
class C() {
  final int f1;
  final int f2;
  final int f3;
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 6, 1)],
    );
  }

  test_class_secondaryConstructor_named() async {
    await assertErrorsInCode(
      '''
class A {
  final int x;
  A.named() {}
}
''',
      [error(diag.finalNotInitializedConstructor1, 27, 7)],
    );
  }

  test_class_secondaryConstructor_unnamed_1() async {
    await assertErrorsInCode(
      '''
class A {
  final int x;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor1, 27, 1)],
    );
  }

  test_class_secondaryConstructor_unnamed_2() async {
    await assertErrorsInCode(
      '''
class A {
  final int a;
  final int b;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor2, 42, 1)],
    );
  }

  test_class_secondaryConstructor_unnamed_3() async {
    await assertErrorsInCode(
      '''
class A {
  final int a;
  final int b;
  final int c;
  A() {}
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 57, 1)],
    );
  }

  test_class_secondaryConstructor_unnamed_duplicateField() async {
    await assertErrorsInCode(
      '''
class A {
  A();
  final int x;
  final int x;
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

  Future<void>
  test_class_secondaryConstructor_unnamed_redirecting_error() async {
    await assertErrorsInCode(
      '''
class A {
  final int x;
  A() : this._();
  A._();
}
''',
      [error(diag.finalNotInitializedConstructor1, 45, 3)],
    );
  }

  Future<void>
  test_class_secondaryConstructor_unnamed_redirecting_no_error() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A() : this._();
  A._() : x = 0;
}
''');
  }

  Future<void> test_class_secondaryConstructors_named_noErrors() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A.zero() : x = 0;
  A.one() : x = 1;
}
''');
  }

  test_enum_primaryConstructor_fields1_declaration0_body0() async {
    await assertErrorsInCode(
      '''
enum E() {
  v;
  final int f;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields1_declaration0_body1() async {
    await assertNoErrorsInCode('''
enum E() {
  v;
  final int f;
  this : f = 0;
}
''');
  }

  test_enum_primaryConstructor_fields1_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum E() {
  v;
  final int f;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields1_declaration1_body0() async {
    await assertNoErrorsInCode('''
enum E(this.f) {
  v(0);
  final int f;
  this;
}
''');
  }

  test_enum_primaryConstructor_fields1_noDeclaration_body1() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int f;
  this : f = 0;
}
''',
      [
        error(diag.finalNotInitialized, 26, 1),
        error(diag.primaryConstructorBodyWithoutDeclaration, 31, 13),
      ],
    );
  }

  test_enum_primaryConstructor_fields2_declaration0_body1() async {
    await assertErrorsInCode(
      '''
enum E() {
  v;
  final int f1;
  final int f2;
  this: f1 = 0;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields2_declaration0_body2() async {
    await assertNoErrorsInCode('''
enum E() {
  v;
  final int f1;
  final int f2;
  this: f1 = 0, f2 = 0;
}
''');
  }

  test_enum_primaryConstructor_fields2_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum E() {
  v;
  final int f1;
  final int f2;
}
''',
      [error(diag.finalNotInitializedConstructor2, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields2_declaration1_body0() async {
    await assertErrorsInCode(
      '''
enum E(this.f1) {
  v(0);
  final int f1;
  final int f2;
  this;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields2_declaration1_body1() async {
    await assertNoErrorsInCode('''
enum E(this.f1) {
  v(0);
  final int f1;
  final int f2;
  this : f2 = 0;
}
''');
  }

  test_enum_primaryConstructor_fields2_declaration1_noBody() async {
    await assertErrorsInCode(
      '''
enum E(this.f1) {
  v(0);
  final int f1;
  final int f2;
}
''',
      [error(diag.finalNotInitializedConstructor1, 5, 1)],
    );
  }

  test_enum_primaryConstructor_fields2_declaration2_body0() async {
    await assertNoErrorsInCode('''
enum E(this.f1, this.f2) {
  v(0, 0);
  final int f1;
  final int f2;
  this;
}
''');
  }

  test_enum_primaryConstructor_fields2_declaration2_noBody() async {
    await assertNoErrorsInCode('''
enum E(this.f1, this.f2) {
  v(0, 0);
  final int f1;
  final int f2;
}
''');
  }

  test_enum_primaryConstructor_fields3_declaration0_noBody() async {
    await assertErrorsInCode(
      '''
enum E() {
  v;
  final int f1;
  final int f2;
  final int f3;
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 5, 1)],
    );
  }

  test_enum_secondaryConstructor_unnamed_1() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int x;
  const E();
}
''',
      [error(diag.finalNotInitializedConstructor1, 37, 1)],
    );
  }

  test_enum_secondaryConstructor_unnamed_2() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int a;
  final int b;
  const E();
}
''',
      [error(diag.finalNotInitializedConstructor2, 52, 1)],
    );
  }

  test_enum_secondaryConstructor_unnamed_3() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int a;
  final int b;
  final int c;
  const E();
}
''',
      [error(diag.finalNotInitializedConstructor3Plus, 67, 1)],
    );
  }

  Future<void>
  test_enum_secondaryConstructor_unnamed_redirecting_error() async {
    await assertErrorsInCode(
      '''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._();
}
''',
      [error(diag.finalNotInitializedConstructor1, 70, 3)],
    );
  }

  Future<void>
  test_enum_secondaryConstructor_unnamed_redirecting_no_error() async {
    await assertNoErrorsInCode('''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._() : x = 0;
}
''');
  }

  Future<void> test_enum_secondaryConstructors_named_noErrors() async {
    await assertNoErrorsInCode('''
enum E {
  v1.zero(), v2.one();
  final int x;
  const E.zero() : x = 0;
  const E.one() : x = 1;
}
''');
  }

  test_extensionType_secondaryConstructor_named() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  A.named();
}
''',
      [error(diag.finalNotInitializedConstructor1, 29, 7)],
    );
  }

  test_extensionType_secondaryConstructor_named_constructorFieldInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named() : it = 0;
}
''');
  }

  test_extensionType_secondaryConstructor_named_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named(this.it);
}
''');
  }
}
