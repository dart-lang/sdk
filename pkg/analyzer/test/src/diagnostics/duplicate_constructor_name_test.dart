// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorNameTest);
  });
}

@reflectiveTest
class DuplicateConstructorNameTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  C.foo();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 23, 5),
    ]);
  }

  test_class_augmentation_augments() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_class_augmentation_augments2() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A.named();
  augment A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_class_augmentation_declares() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 42, 7),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  const E.foo();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 45, 5),
    ]);
  }

  test_extensionType_secondary() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  A.foo(this.it);
  A.foo(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 47, 5),
    ]);
  }

  test_extensionType_withPrimary() async {
    await assertErrorsInCode(r'''
extension type A.foo(int it) {
  A.foo(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 33, 5),
    ]);
  }
}
