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

  test_class_augments_class() async {
    await assertNoErrorsInCode(r'''
class A {}

augment class A {}
''');
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

  test_class_constructor_augments_instanceField() async {
    await assertErrorsInCode(
      r'''
class A {
  int foo = 0;
}

augment class A {
  augment A.foo();
}
''',
      [error(diag.augmentationWithoutDeclaration, 48, 7)],
    );
  }

  test_class_constructor_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

augment class A {
  augment A.foo();
}
''',
      [error(diag.augmentationWithoutDeclaration, 49, 7)],
    );
  }

  test_class_instanceField() async {
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

  test_class_instanceField_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}

augment class A {
  augment int foo = 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 44, 7)],
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

  test_class_instanceField_augments_staticField() async {
    await assertErrorsInCode(
      r'''
class A {
  static int foo = 0;
}
augment class A {
  augment int foo = 0;
}
''',
      [
        error(diag.conflictingStaticAndInstance, 23, 3),
        error(diag.augmentationWithoutDeclaration, 54, 7),
      ],
    );
  }

  test_class_instanceField_augments_staticGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int get foo => 0;',
      augmentation: 'int foo = 0;',
      conflictAtAugmentation: false,
    );
  }

  test_class_instanceField_augments_staticMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static void foo() {}',
      augmentation: 'int foo = 0;',
      conflictAtAugmentation: false,
    );
  }

  test_class_instanceField_augments_staticSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static set foo(int _) {}',
      augmentation: 'int foo = 0;',
      conflictAtAugmentation: false,
    );
  }

  test_class_instanceGetter() async {
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

  test_class_instanceGetter_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}

augment class A {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 44, 7)],
    );
  }

  test_class_instanceGetter_augments_staticField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int foo = 0;',
      augmentation: 'int get foo => 0;',
      expectConflict: false,
    );
  }

  test_class_instanceGetter_augments_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment int get foo => 0;
}
''',
      [error(diag.augmentationWithoutDeclaration, 59, 7)],
    );
  }

  test_class_instanceGetter_augments_staticMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static void foo() {}',
      augmentation: 'int get foo => 0;',
      expectConflict: false,
    );
  }

  test_class_instanceGetter_augments_staticSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static set foo(int _) {}',
      augmentation: 'int get foo => 0;',
      expectConflict: false,
    );
  }

  test_class_instanceMethod() async {
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

  test_class_instanceMethod_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}

augment class A {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 44, 7)],
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

  test_class_instanceMethod_augments_staticField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int foo = 0;',
      augmentation: 'void foo() {}',
      expectConflict: false,
    );
  }

  test_class_instanceMethod_augments_staticGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int get foo => 0;',
      augmentation: 'void foo() {}',
      expectConflict: false,
    );
  }

  test_class_instanceMethod_augments_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}
augment class A {
  augment void foo() {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 55, 7)],
    );
  }

  test_class_instanceMethod_augments_staticSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static set foo(int _) {}',
      augmentation: 'void foo() {}',
      expectConflict: false,
    );
  }

  test_class_instanceSetter() async {
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

  test_class_instanceSetter_augments_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.foo();
}

augment class A {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 44, 7)],
    );
  }

  test_class_instanceSetter_augments_staticField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int foo = 0;',
      augmentation: 'set foo(int _) {}',
      expectConflict: false,
    );
  }

  test_class_instanceSetter_augments_staticGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static int get foo => 0;',
      augmentation: 'set foo(int _) {}',
      expectConflict: false,
    );
  }

  test_class_instanceSetter_augments_staticMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'static void foo() {}',
      augmentation: 'set foo(int _) {}',
      expectConflict: false,
    );
  }

  test_class_instanceSetter_augments_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment set foo(int _) {}
}
''',
      [error(diag.augmentationWithoutDeclaration, 59, 7)],
    );
  }

  test_class_staticField() async {
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

  test_class_staticField_augments_instanceField() async {
    await assertErrorsInCode(
      r'''
class A {
  int foo = 0;
}
augment class A {
  augment static int foo = 0;
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 47, 7),
        error(diag.conflictingStaticAndInstance, 66, 3),
      ],
    );
  }

  test_class_staticField_augments_instanceGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int get foo => 0;',
      augmentation: 'static int foo = 0;',
    );
  }

  test_class_staticField_augments_instanceMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'void foo() {}',
      augmentation: 'static int foo = 0;',
    );
  }

  test_class_staticField_augments_instanceSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'set foo(int _) {}',
      augmentation: 'static int foo = 0;',
    );
  }

  test_class_staticGetter() async {
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

  test_class_staticGetter_augments_instanceField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int foo = 0;',
      augmentation: 'static int get foo => 0;',
    );
  }

  test_class_staticGetter_augments_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
augment class A {
  augment static int get foo => 0;
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 52, 7),
        error(diag.conflictingStaticAndInstance, 75, 3),
      ],
    );
  }

  test_class_staticGetter_augments_instanceMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'void foo() {}',
      augmentation: 'static int get foo => 0;',
    );
  }

  test_class_staticGetter_augments_instanceSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'set foo(int _) {}',
      augmentation: 'static int get foo => 0;',
    );
  }

  test_class_staticMethod() async {
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

  test_class_staticMethod_augments_instanceField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int foo = 0;',
      augmentation: 'static void foo() {}',
    );
  }

  test_class_staticMethod_augments_instanceGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int get foo => 0;',
      augmentation: 'static void foo() {}',
    );
  }

  test_class_staticMethod_augments_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
augment class A {
  augment static void foo() {}
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 48, 7),
        error(diag.conflictingStaticAndInstance, 68, 3),
      ],
    );
  }

  test_class_staticMethod_augments_instanceSetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'set foo(int _) {}',
      augmentation: 'static void foo() {}',
    );
  }

  test_class_staticSetter() async {
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

  test_class_staticSetter_augments_instanceField() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int foo = 0;',
      augmentation: 'static set foo(int _) {}',
    );
  }

  test_class_staticSetter_augments_instanceGetter() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'int get foo => 0;',
      augmentation: 'static set foo(int _) {}',
    );
  }

  test_class_staticSetter_augments_instanceMethod() async {
    await _assertClassMemberAugmentationWithoutDeclaration(
      declaration: 'void foo() {}',
      augmentation: 'static set foo(int _) {}',
    );
  }

  test_class_staticSetter_augments_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment static set foo(int _) {}
}
''',
      [
        error(diag.augmentationWithoutDeclaration, 52, 7),
        error(diag.conflictingStaticAndInstance, 71, 3),
      ],
    );
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

  test_enum_instanceField() async {
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

  test_enum_instanceGetter() async {
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

  test_enum_instanceMethod() async {
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

  test_enum_instanceSetter() async {
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

  test_extension_instanceGetter() async {
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

  test_extension_instanceMethod() async {
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

  test_extension_instanceSetter() async {
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

  test_extensionType_instanceGetter() async {
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

  test_extensionType_instanceMethod() async {
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

  test_extensionType_instanceSetter() async {
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

  test_mixin_instanceField() async {
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

  test_mixin_instanceGetter() async {
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

  test_mixin_instanceMethod() async {
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

  test_mixin_instanceMethod_augments_instanceMethod() async {
    await assertNoErrorsInCode(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  augment void foo() {}
}
''');
  }

  test_mixin_instanceSetter() async {
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

  test_topLevel_function_augments_function() async {
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

  test_topLevel_variable_single_augments_variable() async {
    await assertNoErrorsInCode(r'''
int foo = 0;

augment int foo = 1;
''');
  }

  Future<void> _assertClassMemberAugmentationWithoutDeclaration({
    required String declaration,
    required String augmentation,
    bool conflictAtAugmentation = true,
    bool expectConflict = true,
  }) async {
    var code =
        '''
class A {
  $declaration
}
augment class A {
  augment $augmentation
}
''';

    await assertErrorsInCode(code, [
      if (expectConflict)
        error(
          diag.conflictingStaticAndInstance,
          conflictAtAugmentation
              ? code.lastIndexOf('foo')
              : code.indexOf('foo'),
          3,
        ),
      error(
        diag.augmentationWithoutDeclaration,
        code.indexOf('augment $augmentation'),
        7,
      ),
    ]);
  }
}
