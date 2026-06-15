// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExecutableBodyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExecutableBodyTest extends PubPackageResolutionTest {
  test_class_getter_instance_external_hasBody_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo {
//                     ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_getter_instance_external_hasBody_blockBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external int get foo {
//                     ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_getter_instance_external_hasBody_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo => 0;
//                     ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_getter_instance_external_hasBody_expressionBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external int get foo => 0;
//                     ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_getter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo;
}
''');
  }

  test_class_getter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external int get foo;
}
''');
  }

  test_class_getter_instance_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The complete declaration is here.
  augment int get foo => 1;
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_getter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_class_getter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_class_getter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static int get foo;
}
''');
  }

  test_class_getter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  external static int get foo;
}
''');
  }

  test_class_getter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
''');
  }

  test_class_getter_static_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The complete declaration is here.
  augment static int get foo => 1;
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_getter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static int get foo => 0;
}
''');
  }

  test_class_getter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_getter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_instanceGetter_hasBody_augmentation_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The corresponding getter is declared here.
// [context 2] The complete declaration is here.
  augment int foo = 1;
//            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
// [diag.augmentationInducedGetterAlreadyComplete][context 2] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
}
''');
  }

  test_class_instanceGetter_hasBody_augmentation_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  augment abstract final int foo;
}
''');
  }

  test_class_instanceGetter_hasBody_augmentation_instanceField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The complete declaration is here.
  augment final int foo = 1;
//                  ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
}
''');
  }

  test_class_instanceGetter_hasBody_instanceSetter_hasBody_augmentation_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The complete declaration is here.
  set foo(int _) {}
//    ^^^
// [context 2] The complete declaration is here.
  augment int foo = 1;
//            ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
}
''');
  }

  test_class_instanceGetter_hasBody_instanceSetter_hasBody_augmentation_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  set foo(int _) {}
  augment abstract int foo;
}
''');
  }

  test_class_instanceGetter_noBody_augmentation_instanceField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;
  augment final int foo = 1;
}
''');
  }

  test_class_instanceGetter_noBody_instanceSetter_noBody_augmentation_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;
  set foo(int _);
  augment int foo = 1;
}
''');
  }

  test_class_instanceSetter_hasBody_augmentation_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
//    ^^^
// [context 1] The corresponding setter is declared here.
// [context 2] The complete declaration is here.
  augment int foo = 1;
//            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
}
''');
  }

  test_class_method_instance_external_hasBody_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() {}
//                    ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_instance_external_hasBody_blockBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external void foo() {}
//                    ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_instance_external_hasBody_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() => null;
//                    ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_instance_external_hasBody_expressionBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external void foo() => null;
//                    ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo();
}
''');
  }

  test_class_method_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external void foo();
}
''');
  }

  test_class_method_instance_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The complete declaration is here.
  augment void foo() {}
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_method_instance_hasBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
  augment void foo();
}
''');
  }

  test_class_method_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_class_method_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_class_method_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static void foo();
}
''');
  }

  test_class_method_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  external static void foo();
}
''');
  }

  test_class_method_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
''');
  }

  test_class_method_static_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The complete declaration is here.
  augment static void foo() {}
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_method_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static void foo() {}
}
''');
  }

  test_class_method_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_method_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_operator_instance_external_hasBody_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int operator +(int other) {
//                                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_operator_instance_external_hasBody_blockBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external int operator +(int other) {
//                                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_operator_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int operator +(int other);
}
''');
  }

  test_class_operator_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external int operator +(int other);
}
''');
  }

  test_class_operator_instance_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator +(A _) => this;
//           ^
// [context 1] The complete declaration is here.
  augment A operator +(A _) => this;
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_setter_instance_external_hasBody_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void set foo(int v) {}
//                             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_setter_instance_external_hasBody_blockBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external void set foo(int v) {}
//                             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_setter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void set foo(int v);
}
''');
  }

  test_class_setter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  external void set foo(int v);
}
''');
  }

  test_class_setter_instance_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
//    ^^^
// [context 1] The complete declaration is here.
  augment set foo(int _) {}
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_setter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_class_setter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_class_setter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static set foo(int _);
}
''');
  }

  test_class_setter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  external static set foo(int _);
}
''');
  }

  test_class_setter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
''');
  }

  test_class_setter_static_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
//           ^^^
// [context 1] The complete declaration is here.
  augment static set foo(int _) {}
//^^^^^^^
// [diag.functionAlreadyComplete][context 1] The augmentation can't provide a body because the function or member is already complete.
}
''');
  }

  test_class_setter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static set foo(int _) {}
}
''');
  }

  test_class_setter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_setter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_staticField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract int foo;
//                    ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
}
''');
  }

  test_class_staticField_abstract_completeAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract int foo;
  augment static int get foo => 0;
  augment static set foo(int _) {}
}
''');
  }

  test_class_staticField_abstract_incompleteGetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract int foo;
//                    ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _) {}
}
''');
  }

  test_class_staticField_abstract_incompleteSetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract int foo;
//                    ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
  augment static int get foo => 0;
}
''');
  }

  test_class_staticField_abstract_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static abstract int foo;
//       ^^^^^^^^
// [diag.abstractStaticField] Static fields can't be declared 'abstract'.
}
''');
  }

  test_class_staticField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract final int foo;
//                          ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
}
''');
  }

  test_class_staticField_abstractFinal_completeAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract final int foo;
  augment static int get foo => 0;
}
''');
  }

  test_class_staticField_abstractFinal_incompleteGetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static abstract final int foo;
//                          ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment static abstract final int foo;
}
''');
  }

  test_class_staticGetter_hasBody_augmentation_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
// [context 2] The complete declaration is here.
  augment static int foo = 1;
//                   ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
// [diag.augmentationInducedGetterAlreadyComplete][context 2] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
}
''');
  }

  test_class_staticGetter_hasBody_augmentation_staticField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  augment static abstract final int foo;
}
''');
  }

  test_class_staticGetter_hasBody_augmentation_staticField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The complete declaration is here.
  augment static final int foo = 1;
//                         ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
}
''');
  }

  test_class_staticGetter_hasBody_staticSetter_hasBody_augmentation_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The complete declaration is here.
  static set foo(int _) {}
//           ^^^
// [context 2] The complete declaration is here.
  augment static int foo = 1;
//                   ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
}
''');
  }

  test_class_staticGetter_hasBody_staticSetter_hasBody_augmentation_staticField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  static set foo(int _) {}
  augment static abstract int foo;
}
''');
  }

  test_class_staticGetter_noBody_augmentation_staticField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
  augment static final int foo = 1;
}
''');
  }

  test_class_staticGetter_noBody_staticSetter_noBody_augmentation_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
  static set foo(int _);
  augment static int foo = 1;
}
''');
  }

  test_class_staticSetter_hasBody_augmentation_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
//           ^^^
// [context 1] The corresponding setter is declared here.
// [context 2] The complete declaration is here.
  augment static int foo = 1;
//                   ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
}
''');
  }

  test_enum_getter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_enum_getter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_enum_getter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_getter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_getter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_enum_getter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_enum_getter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_getter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_method_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_enum_method_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_enum_method_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_method_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_method_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_enum_method_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_enum_method_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_method_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_setter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_enum_setter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_enum_setter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_setter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_setter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_enum_setter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_enum_setter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_setter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_getter_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
  augment int get foo => 0;
}
''');
  }

  test_extension_getter_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
//        ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment int get foo;
}
''');
  }

  test_extension_getter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_getter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_getter_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}
''');
  }

  test_extension_getter_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  int get foo => 0;
}
''');
  }

  test_extension_getter_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
//        ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_getter_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  int get foo;
//        ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_getter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_extension_getter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_extension_getter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_getter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_getter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}
''');
  }

  test_extension_getter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static int get foo => 0;
}
''');
  }

  test_extension_getter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_getter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_method_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
  augment void foo() {}
}
''');
  }

  test_extension_method_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
//     ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment void foo();
}
''');
  }

  test_extension_method_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external void foo();
}
''');
  }

  test_extension_method_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external void foo();
}
''');
  }

  test_extension_method_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}
''');
  }

  test_extension_method_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  void foo() {}
}
''');
  }

  test_extension_method_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
//     ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_method_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  void foo();
//     ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_method_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_extension_method_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_extension_method_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_method_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_method_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {}
}
''');
  }

  test_extension_method_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static void foo() {}
}
''');
  }

  test_extension_method_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_method_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_operator_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int operator -(int _);
//             ^
// [diag.functionNotCompleteAfterAugmentations] The function or member '-' must have a body after all augmentations are applied.
  augment int operator -(int _);
}
''');
  }

  test_extension_operator_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int operator -(int _);
//             ^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_operator_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  int operator -(int _);
//             ^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_setter_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
  augment set foo(int _) {}
}
''');
  }

  test_extension_setter_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
//    ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment set foo(int _);
}
''');
  }

  test_extension_setter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_setter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_setter_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}
''');
  }

  test_extension_setter_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  set foo(int _) {}
}
''');
  }

  test_extension_setter_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
//    ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_setter_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  set foo(int _);
//    ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_setter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_extension_setter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_extension_setter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_setter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_setter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _) {}
}
''');
  }

  test_extension_setter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static set foo(int _) {}
}
''');
  }

  test_extension_setter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_setter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_getter_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
  augment int get foo => 0;
}
''');
  }

  test_extensionType_getter_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
//        ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment int get foo;
}
''');
  }

  test_extensionType_getter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_getter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_getter_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo => 0;
}
''');
  }

  test_extensionType_getter_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  int get foo => 0;
}
''');
  }

  test_extensionType_getter_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
//^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_getter_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  int get foo;
//^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_getter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_extensionType_getter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_extensionType_getter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_getter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_getter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo => 0;
}
''');
  }

  test_extensionType_getter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static int get foo => 0;
}
''');
  }

  test_extensionType_getter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_getter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_method_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
  augment void foo() {}
}
''');
  }

  test_extensionType_method_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
//     ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment void foo();
}
''');
  }

  test_extensionType_method_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_method_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_method_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo() {}
}
''');
  }

  test_extensionType_method_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  void foo() {}
}
''');
  }

  test_extensionType_method_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
//^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_method_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  void foo();
//^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_method_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_extensionType_method_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_extensionType_method_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_method_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_method_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo() {}
}
''');
  }

  test_extensionType_method_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static void foo() {}
}
''');
  }

  test_extensionType_method_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_method_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_setter_instance_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
  augment set foo(int _) {}
}
''');
  }

  test_extensionType_setter_instance_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
//    ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment set foo(int _);
}
''');
  }

  test_extensionType_setter_instance_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_setter_instance_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_setter_instance_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _) {}
}
''');
  }

  test_extensionType_setter_instance_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  set foo(int _) {}
}
''');
  }

  test_extensionType_setter_instance_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_setter_instance_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_setter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_extensionType_setter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_extensionType_setter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_setter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_setter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _) {}
}
''');
  }

  test_extensionType_setter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static set foo(int _) {}
}
''');
  }

  test_extensionType_setter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_setter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int i) {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_local_function_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo() {}
  foo();
}
''');
  }

  test_mixin_getter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_mixin_getter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_mixin_getter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_getter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_getter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
}
''');
  }

  test_mixin_getter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static int get foo => 0;
}
''');
  }

  test_mixin_getter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_getter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_method_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_mixin_method_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_mixin_method_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_method_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_method_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
}
''');
  }

  test_mixin_method_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static void foo() {}
}
''');
  }

  test_mixin_method_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_method_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_setter_static_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_mixin_setter_static_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_mixin_setter_static_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_setter_static_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_setter_static_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _) {}
}
''');
  }

  test_mixin_setter_static_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static set foo(int _) {}
}
''');
  }

  test_mixin_setter_static_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_setter_static_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
mixin M {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_topLevel_function_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
augment void foo() {}
''');
  }

  test_topLevel_function_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
//   ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment void foo();
''');
  }

  test_topLevel_function_external_hasBody_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() {}
//                  ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevel_function_external_hasBody_blockBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
external void foo() {}
//                  ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevel_function_external_hasBody_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() => null;
//                  ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevel_function_external_hasBody_expressionBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
external void foo() => null;
//                  ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevel_function_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo();
''');
  }

  test_topLevel_function_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
external void foo();
''');
  }

  test_topLevel_function_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
''');
  }

  test_topLevel_function_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
//   ^^^
// [context 1] The complete declaration is here.
augment void foo() {}
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevel_function_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
void foo() {}
''');
  }

  test_topLevel_function_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
//        ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_function_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
void foo();
//        ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_getter_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
augment int get foo => 0;
''');
  }

  test_topLevel_getter_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
//      ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment int get foo;
''');
  }

  test_topLevel_getter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external int get foo;
''');
  }

  test_topLevel_getter_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
external int get foo;
''');
  }

  test_topLevel_getter_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
''');
  }

  test_topLevel_getter_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The complete declaration is here.
augment int get foo => 1;
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevel_getter_hasBody_augmentation_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The corresponding getter is declared here.
// [context 2] The complete declaration is here.
augment int foo = 1;
//          ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
// [diag.augmentationInducedGetterAlreadyComplete][context 2] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
''');
  }

  test_topLevel_getter_hasBody_augmentation_variable_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
augment abstract final int foo;
''');
  }

  test_topLevel_getter_hasBody_augmentation_variable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The complete declaration is here.
augment final int foo = 1;
//                ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
''');
  }

  test_topLevel_getter_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
int get foo => 0;
''');
  }

  test_topLevel_getter_hasBody_setter_hasBody_augmentation_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The complete declaration is here.
set foo(int _) {}
//  ^^^
// [context 2] The complete declaration is here.
augment int foo = 1;
//          ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
''');
  }

  test_topLevel_getter_hasBody_setter_hasBody_augmentation_variable_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
set foo(int _) {}
augment abstract int foo;
''');
  }

  test_topLevel_getter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_getter_noBody_augmentation_variable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
augment final int foo = 1;
''');
  }

  test_topLevel_getter_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_getter_noBody_setter_noBody_augmentation_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
set foo(int _);
augment int foo = 1;
''');
  }

  test_topLevel_setter_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
augment set foo(int _) {}
''');
  }

  test_topLevel_setter_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
//  ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment set foo(int _);
''');
  }

  test_topLevel_setter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external set foo(int _);
''');
  }

  test_topLevel_setter_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
external set foo(int _);
''');
  }

  test_topLevel_setter_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
''');
  }

  test_topLevel_setter_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
//  ^^^
// [context 1] The complete declaration is here.
augment set foo(int _) {}
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevel_setter_hasBody_augmentation_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
//  ^^^
// [context 1] The corresponding setter is declared here.
// [context 2] The complete declaration is here.
augment int foo = 1;
//          ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
''');
  }

  test_topLevel_setter_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
set foo(int _) {}
''');
  }

  test_topLevel_setter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_setter_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
set foo(int _);
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevel_variable_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
''');
  }

  test_topLevel_variable_abstract_completeAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
augment int get foo => 0;
augment set foo(int _) {}
''');
  }

  test_topLevel_variable_abstract_incompleteGetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
augment set foo(int _) {}
''');
  }

  test_topLevel_variable_abstract_incompleteSetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
augment int get foo => 0;
''');
  }

  test_topLevel_variable_abstract_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
abstract int foo;
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');
  }

  test_topLevel_variable_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
//                 ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
''');
  }

  test_topLevel_variable_abstractFinal_completeAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
augment int get foo => 0;
''');
  }

  test_topLevel_variable_abstractFinal_incompleteGetterAfterAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
//                 ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
augment abstract final int foo;
''');
  }
}
