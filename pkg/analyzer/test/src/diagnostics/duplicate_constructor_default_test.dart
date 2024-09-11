// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorDefaultTest);
  });
}

@reflectiveTest
class DuplicateConstructorDefaultTest extends PubPackageResolutionTest {
  test_class_augmentation_augments() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A();
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

  test_class_augmentation_declares() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A();
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
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 42, 1),
    ]);
  }

  test_class_empty_empty() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 1),
    ]);
  }

  test_class_empty_new() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 5),
    ]);
  }

  test_class_new_empty() async {
    await assertErrorsInCode(r'''
class C {
  C.new();
  C();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 23, 1),
    ]);
  }

  test_class_new_new() async {
    await assertErrorsInCode(r'''
class C {
  C.new();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 23, 5),
    ]);
  }

  test_enum_empty_empty() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E();
  const E();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 35, 1),
    ]);
  }

  test_enum_empty_new() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E();
  const E.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 35, 5),
    ]);
  }

  test_enum_new_empty() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E.new();
  const E();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 39, 1),
    ]);
  }

  test_enum_new_new() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E.new();
  const E.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 39, 5),
    ]);
  }

  test_extensionType_empty_empty() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  A(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 29, 1),
    ]);
  }

  test_extensionType_empty_new() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  A.new(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 29, 5),
    ]);
  }

  test_extensionType_new_empty() async {
    await assertErrorsInCode(r'''
extension type A.new(int it) {
  A(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 33, 1),
    ]);
  }

  test_extensionType_new_new() async {
    await assertErrorsInCode(r'''
extension type A.new(int it) {
  A.new(this.it);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 33, 5),
    ]);
  }
}
