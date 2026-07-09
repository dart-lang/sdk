// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationReturnTypeMismatchTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationReturnTypeMismatchTest extends PubPackageResolutionTest {
  test_class_instanceField_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? foo;
}

augment class A {
  augment abstract int? foo;
}
''');
  }

  test_class_instanceField_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? foo;
}

augment class A {
  augment abstract String? foo;
//                         ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
}
''');
  }

  test_class_instanceField_multiple_oneMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String? foo;
  int? bar;
}

augment class A {
  augment abstract String? foo, bar;
//                              ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
}
''');
  }

  test_class_instanceGetter_instanceField_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get foo => 0;
}

augment class A {
  augment abstract final String? foo;
//                               ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
}
''');
  }

  test_class_instanceGetter_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment String get foo;
//        ^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'String' must be the same as the introductory declaration's return type 'int'.
}
''');
  }

  test_class_instanceMethod_void_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

augment class A {
  augment int foo();
//        ^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
}
''');
  }

  test_class_instanceMethod_void_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo();
}
''');
  }

  test_class_staticField_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int? foo;
}

augment class A {
  augment static abstract int? foo;
}
''');
  }

  test_class_staticField_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int? foo;
}

augment class A {
  augment static abstract String? foo;
//                                ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
}
''');
  }

  test_extension_instanceGetter_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

augment extension E {
  augment String get foo;
//        ^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'String' must be the same as the introductory declaration's return type 'int'.
}
''');
  }

  test_extension_instanceMethod_void_int() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

augment extension E {
  augment int foo();
//        ^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
}
''');
  }

  test_extensionType_instanceGetter_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

augment extension type A {
  augment String get foo;
//        ^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'String' must be the same as the introductory declaration's return type 'int'.
}
''');
  }

  test_extensionType_instanceMethod_void_int() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A {
  augment int foo();
//        ^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
}
''');
  }

  test_mixin_instanceGetter_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

augment mixin M {
  augment String get foo;
//        ^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'String' must be the same as the introductory declaration's return type 'int'.
}
''');
  }

  test_mixin_instanceMethod_void_int() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

augment mixin M {
  augment int foo();
//        ^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
}
''');
  }

  test_topLevelFunction_dynamic_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic foo() => null;

augment Object? foo();
//      ^^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'Object?' must be the same as the introductory declaration's return type 'dynamic'.
''');
  }

  test_topLevelFunction_int_int_withImportPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';
import 'dart:core' as core;

int foo() => 0;

augment core.int foo();
''');
  }

  test_topLevelFunction_objectQuestion_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
Object? foo() => null;

augment dynamic foo();
//      ^^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'dynamic' must be the same as the introductory declaration's return type 'Object?'.
''');
  }

  test_topLevelFunction_void_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}

augment int foo();
//      ^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
''');
  }

  test_topLevelFunction_void_int_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef IntAlias = int;

void foo() {}

augment IntAlias foo();
//      ^^^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'IntAlias' must be the same as the introductory declaration's return type 'void'.
''');
  }

  test_topLevelFunction_void_int_withImportPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;
void foo() {}

augment core.int foo();
//      ^^^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'int' must be the same as the introductory declaration's return type 'void'.
''');
  }

  test_topLevelFunction_void_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}

augment foo();
''');
  }

  test_topLevelFunction_void_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}

augment void foo();
''');
  }

  test_topLevelFunction_void_void_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef VoidAlias = void;

void foo() {}

augment VoidAlias foo();
''');
  }

  test_topLevelGetter_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

augment String get foo;
//      ^^^^^^
// [diag.augmentationReturnTypeMismatch] The augmentation's return type 'String' must be the same as the introductory declaration's return type 'int'.
''');
  }

  test_topLevelGetter_topLevelVariable_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
int? get foo => 0;

augment abstract final String? foo;
//                             ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
''');
  }

  test_topLevelVariable_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int? foo;

augment abstract int? foo;
''');
  }

  test_topLevelVariable_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
int? foo;

augment abstract String? foo;
//                       ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
''');
  }

  test_topLevelVariable_multiple_oneMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
String? foo;
int? bar;

augment abstract String? foo, bar;
//                            ^^^
// [diag.augmentationInducedGetterReturnTypeMismatch] The getter induced by this augmentation has return type 'String?', but the getter being augmented has return type 'int?'.
''');
  }
}
