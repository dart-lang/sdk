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
    await assertNoErrorsInCode(r'''
class C {
  external int get foo;
}
''');
  }

  test_class_getter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {
  external static int get foo;
}
''');
  }

  test_class_getter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
class A {
  external static int get foo;
}
''');
  }

  test_class_getter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class C {
  external void foo();
}
''');
  }

  test_class_method_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
  augment void foo();
}
''');
  }

  test_class_method_static_augmentation_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {
  external static void foo();
}
''');
  }

  test_class_method_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
class A {
  external static void foo();
}
''');
  }

  test_class_method_static_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class C {
  external int operator +(int other);
}
''');
  }

  test_class_operator_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class C {
  external void set foo(int v);
}
''');
  }

  test_class_setter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {
  external static set foo(int _);
}
''');
  }

  test_class_setter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
class A {
  external static set foo(int _);
}
''');
  }

  test_class_setter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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

  test_enum_getter_static_augmentation_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_getter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_getter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_enum_getter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_method_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_method_static_hasBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_enum_method_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_setter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_setter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_enum_setter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_getter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_getter_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  int get foo => 0;
}
''');
  }

  test_extension_getter_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_getter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_getter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static int get foo => 0;
}
''');
  }

  test_extension_getter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external void foo();
}
''');
  }

  test_extension_method_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external void foo();
}
''');
  }

  test_extension_method_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  void foo() {}
}
''');
  }

  test_extension_method_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_method_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_method_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static void foo() {}
}
''');
  }

  test_extension_method_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_setter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_setter_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  set foo(int _) {}
}
''');
  }

  test_extension_setter_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_setter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_setter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static set foo(int _) {}
}
''');
  }

  test_extension_setter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_getter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_getter_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  int get foo => 0;
}
''');
  }

  test_extensionType_getter_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_getter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_getter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  static int get foo => 0;
}
''');
  }

  test_extensionType_getter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_method_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_method_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  void foo() {}
}
''');
  }

  test_extensionType_method_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_method_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_method_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  static void foo() {}
}
''');
  }

  test_extensionType_method_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_setter_instance_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_setter_instance_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  set foo(int _) {}
}
''');
  }

  test_extensionType_setter_instance_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_setter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_setter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {
  static set foo(int _) {}
}
''');
  }

  test_extensionType_setter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
void f() {
  void foo() {}
  foo();
}
''');
  }

  test_mixin_getter_static_augmentation_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_getter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_getter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static int get foo => 0;
}
''');
  }

  test_mixin_getter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_method_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_method_static_hasBody() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static void foo() {}
}
''');
  }

  test_mixin_method_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_setter_static_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_setter_static_hasBody() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static set foo(int _) {}
}
''');
  }

  test_mixin_setter_static_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
external void foo();
''');
  }

  test_topLevel_function_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
external void foo();
''');
  }

  test_topLevel_function_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
external int get foo;
''');
  }

  test_topLevel_getter_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
external int get foo;
''');
  }

  test_topLevel_getter_hasBody() async {
    await assertNoErrorsInCode(r'''
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

  test_topLevel_getter_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
int get foo => 0;
''');
  }

  test_topLevel_getter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
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

  test_topLevel_setter_augmentation_hasBody() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
external set foo(int _);
''');
  }

  test_topLevel_setter_external_noBody_language305() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.5
external set foo(int _);
''');
  }

  test_topLevel_setter_hasBody() async {
    await assertNoErrorsInCode(r'''
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

  test_topLevel_setter_hasBody_language305() async {
    await assertNoErrorsInCode(r'''
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
}
