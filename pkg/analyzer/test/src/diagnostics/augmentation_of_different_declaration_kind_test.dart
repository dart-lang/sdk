// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
  test_class_augments_enum() async {
    await assertErrorsInCode(
      r'''
enum A {v}
augment class A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 5, 1)],
        ),
      ],
    );
  }

  test_class_augments_extension() async {
    await assertErrorsInCode(
      r'''
extension A on int {}
augment class A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          22,
          7,
          contextMessages: [message(testFile, 10, 1)],
        ),
      ],
    );
  }

  test_class_augments_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
augment class A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          28,
          7,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }

  test_class_augments_function() async {
    await assertErrorsInCode(
      r'''
void foo() {}
augment class foo {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          14,
          7,
          contextMessages: [message(testFile, 5, 3)],
        ),
      ],
    );
  }

  test_class_augments_getter() async {
    await assertErrorsInCode(
      r'''
int get foo => 0;
augment class foo {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          18,
          7,
          contextMessages: [message(testFile, 8, 3)],
        ),
      ],
    );
  }

  test_class_augments_mixin() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment class A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_class_augments_setter() async {
    await assertErrorsInCode(
      r'''
set foo(int _) {}
augment class foo {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          18,
          7,
          contextMessages: [message(testFile, 4, 3)],
        ),
      ],
    );
  }

  test_class_augments_variable() async {
    await assertErrorsInCode(
      r'''
int foo = 0;
augment class foo {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          13,
          7,
          contextMessages: [message(testFile, 4, 3)],
        ),
      ],
    );
  }

  test_class_constructor_augments_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A.foo();
}
augment class A {
  augment A.foo();
}
''');
  }

  test_class_constructor_augments_staticField() async {
    await assertErrorsInCode(
      r'''
class A {
  static int foo = 0;
}
augment class A {
  augment A.foo();
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          54,
          7,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_class_constructor_augments_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}
augment class A {
  augment A.foo();
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          55,
          7,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_class_instanceField_augments_instanceField() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}
augment class A {
  augment int foo = 1;
}
''');
  }

  test_class_instanceField_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
augment class A {
  augment int foo = 0;
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          48,
          7,
          contextMessages: [message(testFile, 17, 3)],
        ),
        error(
          diag.duplicateDefinition,
          60,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_class_instanceGetter_augments_instanceField() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}
augment class A {
  augment int get foo => 0;
}
''');
  }

  test_class_instanceGetter_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
augment class A {
  augment int get foo => 0;
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          48,
          7,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_class_instanceMethod_augments_instanceField() async {
    await assertErrorsInCode(
      r'''
class A {
  int foo = 0;
}
augment class A {
  augment void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          47,
          7,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_instanceMethod_augments_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
augment class A {
  augment void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          52,
          7,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_class_instanceMethod_augments_instanceMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}
augment class A {
  augment void foo() {}
}
''');
  }

  test_class_instanceMethod_augments_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          52,
          7,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_instanceSetter_augments_instanceField() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}
augment class A {
  augment set foo(int _) {}
}
''');
  }

  test_class_instanceSetter_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
augment class A {
  augment set foo(int _) {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          48,
          7,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_class_staticField_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}
augment class A {
  augment static int foo = 0;
}
''',
      [
        error(diag.conflictingConstructorAndStaticField, 14, 3),
        error(
          diag.augmentationOfDifferentDeclarationKind,
          43,
          7,
          contextMessages: [message(testFile, 14, 3)],
        ),
      ],
    );
  }

  test_class_staticField_augments_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}
augment class A {
  augment static int foo = 0;
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          55,
          7,
          contextMessages: [message(testFile, 24, 3)],
        ),
        error(
          diag.duplicateDefinition,
          74,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_class_staticGetter_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}
augment class A {
  augment static int get foo => 0;
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          43,
          7,
          contextMessages: [message(testFile, 14, 3)],
        ),
      ],
    );
  }

  test_class_staticGetter_augments_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}
augment class A {
  augment static int get foo => 0;
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          55,
          7,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_class_staticMethod_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}
augment class A {
  augment static void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          43,
          7,
          contextMessages: [message(testFile, 14, 3)],
        ),
      ],
    );
  }

  test_class_staticMethod_augments_staticField() async {
    await assertErrorsInCode(
      r'''
class A {
  static int foo = 0;
}
augment class A {
  augment static void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          54,
          7,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_class_staticMethod_augments_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment static void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          59,
          7,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_class_staticMethod_augments_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment static void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          59,
          7,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_class_staticSetter_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}
augment class A {
  augment static set foo(int _) {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          43,
          7,
          contextMessages: [message(testFile, 14, 3)],
        ),
      ],
    );
  }

  test_class_staticSetter_augments_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}
augment class A {
  augment static set foo(int _) {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          55,
          7,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_enum_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment enum A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_enum_constant_augments_constant() async {
    await assertNoErrorsInCode(r'''
enum A {
  foo
}
augment enum A {
  augment foo(),
}
''');
  }

  test_enum_constant_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
enum A {
  v;
  void foo() {}
}
augment enum A {
  augment foo(),
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 51, 7),
        error(diag.conflictingStaticAndInstance, 59, 3),
      ],
    );
  }

  test_enum_staticMethod_augments_constant() async {
    await assertErrorsInCode(
      r'''
enum A {
  foo
}
augment enum A {;
  augment static void foo() {}
}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          37,
          7,
          contextMessages: [message(testFile, 11, 3)],
        ),
      ],
    );
  }

  test_extension_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment extension A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_extensionType_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment extension type A(int it) {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_function_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment void A() {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_mixin_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment mixin A {}
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_typedef_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment typedef A = int;
''',
      [error(diag.typedefAugmentation, 11, 7)],
    );
  }

  test_variable_augments_class() async {
    await assertErrorsInCode(
      r'''
class A {}
augment int A = 0;
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          11,
          7,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_variable_augments_function() async {
    await assertErrorsInCode(
      r'''
void foo() {}
augment int foo = 0;
''',
      [
        error(
          diag.augmentationOfDifferentDeclarationKind,
          14,
          7,
          contextMessages: [message(testFile, 5, 3)],
        ),
      ],
    );
  }
}
