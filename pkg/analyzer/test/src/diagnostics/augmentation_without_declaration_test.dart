// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationWithoutDeclarationTest);
  });
}

@reflectiveTest
class AugmentationWithoutDeclarationTest extends PubPackageResolutionTest {
  test_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }

  test_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment A.named();
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 47, 7),
    ]);
  }

  test_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment int foo = 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 47, 7),
    ]);
  }

  test_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 47, 7),
    ]);
  }

  test_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 47, 7),
    ]);
  }

  test_class_method_valid() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment void foo() {}
}
''');
  }

  test_class_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {
  augment set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 47, 7),
    ]);
  }

  test_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }

  test_topLevel_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment void foo() {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }

  test_topLevel_function_valid() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void foo() {}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment void foo() {}
''');
  }

  test_topLevel_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment int get foo => 0;
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }

  test_topLevel_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment set foo(int _) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }

  test_topLevel_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment int foo = 0;
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION, 27, 7),
    ]);
  }
}
