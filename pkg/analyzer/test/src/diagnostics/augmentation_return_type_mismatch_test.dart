// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationReturnTypeMismatchTest);
  });
}

@reflectiveTest
class AugmentationReturnTypeMismatchTest extends PubPackageResolutionTest {
  test_class_getter_int_String() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}

augment class A {
  augment String get foo;
}
''',
      [error(diag.augmentationReturnTypeMismatch, 61, 6)],
    );
  }

  test_class_method_void_int() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

augment class A {
  augment int foo();
}
''',
      [error(diag.augmentationReturnTypeMismatch, 57, 3)],
    );
  }

  test_class_method_void_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo();
}
''');
  }

  test_extension_getter_int_String() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  int get foo => 0;
}

augment extension E {
  augment String get foo;
}
''',
      [
        error(diag.augmentationReturnTypeMismatch, 76, 6),
        error(diag.extensionDeclaresAbstractMember, 87, 3),
      ],
    );
  }

  test_extension_method_void_int() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void foo() {}
}

augment extension E {
  augment int foo();
}
''',
      [
        error(diag.augmentationReturnTypeMismatch, 72, 3),
        error(diag.extensionDeclaresAbstractMember, 76, 3),
      ],
    );
  }

  test_extensionType_getter_int_String() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  int get foo => 0;
}

augment extension type A(int it) {
  augment String get foo;
}
''',
      [
        error(diag.extensionTypeWithAbstractMember, 87, 23),
        error(diag.augmentationReturnTypeMismatch, 95, 6),
      ],
    );
  }

  test_extensionType_method_void_int() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A(int it) {
  augment int foo();
}
''',
      [
        error(diag.extensionTypeWithAbstractMember, 83, 18),
        error(diag.augmentationReturnTypeMismatch, 91, 3),
      ],
    );
  }

  test_mixin_getter_int_String() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int get foo => 0;
}

augment mixin M {
  augment String get foo;
}
''',
      [error(diag.augmentationReturnTypeMismatch, 61, 6)],
    );
  }

  test_mixin_method_void_int() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
}

augment mixin M {
  augment int foo();
}
''',
      [error(diag.augmentationReturnTypeMismatch, 57, 3)],
    );
  }

  test_topLevelFunction_int_int_withImportPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
import 'dart:core' as core;

int foo() => 0;

augment core.int foo();
''');
  }

  test_topLevelFunction_void_int() async {
    await assertErrorsInCode(
      r'''
void foo() {}

augment int foo();
''',
      [error(diag.augmentationReturnTypeMismatch, 23, 3)],
    );
  }

  test_topLevelFunction_void_int_viaTypeAlias() async {
    await assertErrorsInCode(
      r'''
typedef IntAlias = int;

void foo() {}

augment IntAlias foo();
''',
      [error(diag.augmentationReturnTypeMismatch, 48, 8)],
    );
  }

  test_topLevelFunction_void_int_withImportPrefix() async {
    await assertErrorsInCode(
      r'''
import 'dart:core' as core;
void foo() {}

augment core.int foo();
''',
      [error(diag.augmentationReturnTypeMismatch, 51, 8)],
    );
  }

  test_topLevelFunction_void_nothing() async {
    await assertNoErrorsInCode(r'''
void foo() {}

augment foo();
''');
  }

  test_topLevelFunction_void_void() async {
    await assertNoErrorsInCode(r'''
void foo() {}

augment void foo();
''');
  }

  test_topLevelFunction_void_void_viaTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef VoidAlias = void;

void foo() {}

augment VoidAlias foo();
''');
  }

  test_topLevelGetter_int_String() async {
    await assertErrorsInCode(
      r'''
int get foo => 0;

augment String get foo;
''',
      [error(diag.augmentationReturnTypeMismatch, 27, 6)],
    );
  }
}
