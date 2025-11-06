// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalNotInitializedConstructorTest);
  });
}

@reflectiveTest
class FinalNotInitializedConstructorTest extends PubPackageResolutionTest {
  test_class_1() async {
    await assertErrorsInCode(
      '''
class A {
  final int x;
  A() {}
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor1, 27, 1)],
    );
  }

  test_class_2() async {
    await assertErrorsInCode(
      '''
class A {
  final int a;
  final int b;
  A() {}
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor2, 42, 1)],
    );
  }

  test_class_3() async {
    await assertErrorsInCode(
      '''
class A {
  final int a;
  final int b;
  final int c;
  A() {}
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor3Plus, 57, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsConstructor2_2of2() async {
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
  test_class_augmentation_augmentsConstructor_1of1() async {
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
  test_class_augmentation_augmentsConstructor_1of2() async {
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
        CompileTimeErrorCode.finalNotInitializedConstructor1,
        60,
        1,
        messageContains: ['f2'],
      ),
    ]);

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augmentsConstructor_noInitializers() async {
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
  test_class_augmentation_declaresConstructor_noInitializers() async {
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
    assertErrorsInResult([
      error(CompileTimeErrorCode.finalNotInitializedConstructor1, 42, 1),
    ]);
  }

  Future<void> test_class_redirecting_error() async {
    await assertErrorsInCode(
      '''
class A {
  final int x;
  A() : this._();
  A._();
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor1, 45, 1)],
    );
  }

  Future<void> test_class_redirecting_no_error() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A() : this._();
  A._() : x = 0;
}
''');
  }

  Future<void> test_class_two_constructors_no_errors() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A.zero() : x = 0;
  A.one() : x = 1;
}
''');
  }

  test_enum_1() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int x;
  const E();
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor1, 37, 1)],
    );
  }

  test_enum_2() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int a;
  final int b;
  const E();
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor2, 52, 1)],
    );
  }

  test_enum_3Plus() async {
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
      [error(CompileTimeErrorCode.finalNotInitializedConstructor3Plus, 67, 1)],
    );
  }

  Future<void> test_enum_redirecting_error() async {
    await assertErrorsInCode(
      '''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._();
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor1, 70, 1)],
    );
  }

  Future<void> test_enum_redirecting_no_error() async {
    await assertNoErrorsInCode('''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._() : x = 0;
}
''');
  }

  Future<void> test_enum_two_constructors_no_errors() async {
    await assertNoErrorsInCode('''
enum E {
  v1.zero(), v2.one();
  final int x;
  const E.zero() : x = 0;
  const E.one() : x = 1;
}
''');
  }

  test_extensionType() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {
  A.named();
}
''',
      [error(CompileTimeErrorCode.finalNotInitializedConstructor1, 29, 1)],
    );
  }

  test_extensionType_noError_constructorFieldInitializer() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named() : it = 0;
}
''');
  }

  test_extensionType_noError_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  A.named(this.it);
}
''');
  }
}
