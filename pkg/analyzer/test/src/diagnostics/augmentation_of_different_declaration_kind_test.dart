// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationOfDifferentDeclarationKindTest);
  });
}

@reflectiveTest
class AugmentationOfDifferentDeclarationKindTest
    extends PubPackageResolutionTest {
  test_class_augmentedBy_enum() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment enum A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment extension A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_extensionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment extension type A(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment void A() {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment mixin A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_typedef() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment typedef A = int;
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_augmentedBy_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment int A = 0;
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_class_constructor_augmentedBy_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.foo();
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment A.foo();
}
''');
  }

  test_class_constructor_augmentedBy_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.foo();
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int foo = 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_constructor_augmentedBy_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.foo();
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_constructor_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.foo();
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_constructor_augmentedBy_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.foo();
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_field_augmentedBy_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment A.foo();
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_field_augmentedBy_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int foo = 1;
}
''');
  }

  test_class_field_augmentedBy_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int get foo => 0;
}
''');
  }

  test_class_field_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_field_augmentedBy_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment set foo(int _) {}
}
''');
  }

  test_class_getter_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int get foo => 0;
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_method_augmentedBy_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment A.foo();
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_method_augmentedBy_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int foo = 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_method_augmentedBy_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_method_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment void foo() {}
}
''');
  }

  test_class_method_augmentedBy_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_class_setter_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  set foo(int _) {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {
  augment void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_enum_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum A {v}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_enum_constant_augmentedBy_constant() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum A {
  foo
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment enum A {
  augment foo(),
}
''');
  }

  test_enum_constant_augmentedBy_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum A {
  foo
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment enum A {;
  augment static void foo() {}
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 39,
          7),
    ]);
  }

  test_enum_method_augmentedBy_constant() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum A {
  v;
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment enum A {
  augment foo(),
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 38,
          7),
    ]);
  }

  test_extension_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

extension A on int {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_extensionType_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

extension type A(int it) {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_mixin_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

mixin A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_topFunction_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void foo() {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class foo {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_topGetter_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

int get foo => 0;
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class foo {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }

  test_topSetter_augmentedBy_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

set foo(int _) {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class foo {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 19,
          7),
    ]);
  }
}
