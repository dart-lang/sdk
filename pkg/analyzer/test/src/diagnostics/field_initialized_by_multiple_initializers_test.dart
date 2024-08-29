// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedByMultipleInitializersTest);
  });
}

@reflectiveTest
class FinalInitializedByMultipleInitializersTest
    extends PubPackageResolutionTest {
  static const _errorCode =
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS;

  test_class_augmentation2_bothInitialize() async {
    newFile(testFile.path, r'''
part 'a.dart';
part 'b.dart';

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

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f = 1;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([
      error(_errorCode, 56, 1),
    ]);
  }

  test_class_augmentation_augmentationInitializes() async {
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

  test_class_augmentation_bothInitialize() async {
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
  augment A() : f = 1;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(_errorCode, 56, 1),
    ]);
  }

  test_class_augmentation_declarationInitializes() async {
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

  test_class_more_than_two_initializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}
''', [
      error(_errorCode, 34, 1),
      error(_errorCode, 41, 1),
    ]);
  }

  test_class_multiple_names() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, x = 1, y = 0, y = 1 {}
}
''', [
      error(_errorCode, 43, 1),
      error(_errorCode, 57, 1),
    ]);
  }

  test_class_one_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, y = 0 {}
}
''');
  }

  test_class_two_initializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}
''', [
      error(_errorCode, 34, 1),
    ]);
  }

  test_enum_one_initializer() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  final int x;
  final int y;
  const E() : x = 0, y = 0;
}
''');
  }

  test_enum_two_initializers() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int x;
  const E() : x = 0, x = 1;
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 11, 1),
      error(_errorCode, 50, 1),
    ]);
  }
}
