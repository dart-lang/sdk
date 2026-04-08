// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
augment class A {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_class_constructor() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment A.named();
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_field() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment int foo = 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_field_static() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment static int foo = 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_field_valid() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int foo = 1;
}
''');
  }

  test_class_getter() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_getter_static() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment static int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_method() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_method_static() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment static void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_method_valid() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo() {}
}
''');
  }

  test_class_setter() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_setter_static() async {
    await assertErrorsInCode(
      r'''
class A {}

augment class A {
  augment static set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_class_valid() async {
    await assertNoErrorsInCode(r'''
class A {}

augment class A {}
''');
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
augment enum A {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_enum_constructor() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment const A.named();
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 50, 7),
        error(diag.unusedElement, 66, 5),
      ],
    );
  }

  test_enum_field() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment final int foo = 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 50, 7)],
    );
  }

  test_enum_getter() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 50, 7)],
    );
  }

  test_enum_method() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 50, 7)],
    );
  }

  test_enum_setter() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 50, 7)],
    );
  }

  test_extension() async {
    await assertErrorsInCode(
      r'''
augment extension A {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_extension_getter() async {
    await assertErrorsInCode(
      r'''
extension A on int {}

augment extension A {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 47, 7)],
    );
  }

  test_extension_method() async {
    await assertErrorsInCode(
      r'''
extension A on int {}

augment extension A {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 47, 7)],
    );
  }

  test_extension_setter() async {
    await assertErrorsInCode(
      r'''
extension A on int {}

augment extension A {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 47, 7)],
    );
  }

  test_extensionType() async {
    await assertErrorsInCode(
      r'''
augment extension type A(int it) {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_extensionType_constructor() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

augment extension type A(int it) {
  augment A.named() : this(0);
}
''',
      [error(diag.augmentationWithoutDeclaration, 66, 7)],
    );
  }

  test_extensionType_getter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

augment extension type A(int it) {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 66, 7)],
    );
  }

  test_extensionType_method() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

augment extension type A(int it) {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 66, 7)],
    );
  }

  test_extensionType_setter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

augment extension type A(int it) {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 66, 7)],
    );
  }

  test_mixin() async {
    await assertErrorsInCode(
      r'''
augment mixin A {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_mixin_field() async {
    await assertErrorsInCode(
      r'''
mixin A {}

augment mixin A {
  augment int foo = 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_mixin_getter() async {
    await assertErrorsInCode(
      r'''
mixin A {}

augment mixin A {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_mixin_method() async {
    await assertErrorsInCode(
      r'''
mixin A {}

augment mixin A {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_mixin_method_valid() async {
    await assertNoErrorsInCode(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  augment void foo() {}
}
''');
  }

  test_mixin_setter() async {
    await assertErrorsInCode(
      r'''
mixin A {}

augment mixin A {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 32, 7)],
    );
  }

  test_topLevel_function() async {
    await assertErrorsInCode(
      r'''
augment void foo() {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_topLevel_function_valid() async {
    await assertNoErrorsInCode(r'''
void foo() {}

augment void foo() {}
''');
  }

  test_topLevel_getter() async {
    await assertErrorsInCode(
      r'''
augment int get foo => 0;
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_topLevel_setter() async {
    await assertErrorsInCode(
      r'''
augment set foo(int _) {}
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_topLevel_variable_multiple() async {
    await assertErrorsInCode(
      r'''
augment int foo = 0, bar = 0;
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_topLevel_variable_multiple_oneMissing() async {
    await assertErrorsInCode(
      r'''
int bar = 0;

augment int foo = 1, bar = 2;
''',
      [error(diag.augmentationWithoutDeclaration, 14, 7)],
    );
  }

  test_topLevel_variable_single() async {
    await assertErrorsInCode(
      r'''
augment int foo = 0;
''',
      [error(diag.augmentationWithoutDeclaration, 0, 7)],
    );
  }

  test_topLevel_variable_single_valid() async {
    await assertNoErrorsInCode(r'''
int foo = 0;

augment int foo = 1;
''');
  }
}
