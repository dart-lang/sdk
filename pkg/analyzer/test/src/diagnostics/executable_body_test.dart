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
  test_abstractClass_instanceField_abstract_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract dynamic foo;
}
''');
  }

  test_abstractClass_instanceField_abstract_var() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract var foo;
}
''');
  }

  test_abstractClass_instanceField_abstractCovariant_var() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract covariant var foo;
}
''');
  }

  test_class_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  abstract int? foo;
//^^^^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_class_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  abstract final int? foo;
//^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_class_instanceField_external() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int? foo;
}
''');
  }

  test_class_instanceField_externalFinal() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int? foo;
}
''');
  }

  test_class_instanceGetter_expressionBody_augmentation_expressionBody() async {
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

  test_class_instanceGetter_expressionBody_augmentation_instanceField() async {
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

  test_class_instanceGetter_expressionBody_augmentation_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  augment abstract final int foo;
}
''');
  }

  test_class_instanceGetter_expressionBody_augmentation_instanceField_final() async {
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

  test_class_instanceGetter_expressionBody_instanceSetter_blockBody_augmentation_instanceField() async {
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

  test_class_instanceGetter_expressionBody_instanceSetter_blockBody_augmentation_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  set foo(int _) {}
  augment abstract int foo;
}
''');
  }

  test_class_instanceGetter_external_blockBody() async {
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

  test_class_instanceGetter_external_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external int get foo {
//                     ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_instanceGetter_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo => 0;
//                     ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceGetter_external_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external int get foo => 0;
//                     ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo;
}
''');
  }

  test_class_instanceGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external int get foo;
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

  test_class_instanceMethod_blockBody_augmentation_blockBody() async {
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

  test_class_instanceMethod_blockBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
  augment void foo();
}
''');
  }

  test_class_instanceMethod_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() {}
//                    ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceMethod_external_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external void foo() {}
//                    ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceMethod_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() => null;
//                    ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceMethod_external_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external void foo() => null;
//                    ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo();
}
''');
  }

  test_class_instanceMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external void foo();
}
''');
  }

  test_class_instanceMethod_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo();
//^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_class_instanceMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo();
//^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
  augment void foo();
}
''');
  }

  test_class_instanceOperator_expressionBody_augmentation_expressionBody() async {
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

  test_class_instanceOperator_external_blockBody() async {
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

  test_class_instanceOperator_external_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external int operator +(int other) {
//                                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
    return 0;
  }
}
''');
  }

  test_class_instanceOperator_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int operator +(int other);
}
''');
  }

  test_class_instanceOperator_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external int operator +(int other);
}
''');
  }

  test_class_instanceSetter_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) async {}
//               ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_class_instanceSetter_blockBody_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) async* {}
//               ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_class_instanceSetter_blockBody_augmentation_blockBody() async {
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

  test_class_instanceSetter_blockBody_augmentation_instanceField() async {
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

  test_class_instanceSetter_blockBody_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) sync* {}
//               ^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_class_instanceSetter_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void set foo(int v) {}
//                             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceSetter_external_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external void set foo(int v) {}
//                             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_instanceSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void set foo(int v);
}
''');
  }

  test_class_instanceSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class C {
  external void set foo(int v);
}
''');
  }

  test_class_instanceSetter_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_class_noSuchMethod_expressionBody_interface_class_instanceMethod_noBody() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  noSuchMethod(_) => '';
}
class A implements I {
  foo();
//^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
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

  test_class_staticField_abstract_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static abstract int foo;
//       ^^^^^^^^
// [diag.abstractStaticField] Static fields can't be declared 'abstract'.
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

  test_class_staticGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
''');
  }

  test_class_staticGetter_expressionBody_augmentation_expressionBody() async {
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

  test_class_staticGetter_expressionBody_augmentation_staticField() async {
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

  test_class_staticGetter_expressionBody_augmentation_staticField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  augment static abstract final int foo;
}
''');
  }

  test_class_staticGetter_expressionBody_augmentation_staticField_final() async {
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

  test_class_staticGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static int get foo => 0;
}
''');
  }

  test_class_staticGetter_expressionBody_staticSetter_blockBody_augmentation_staticField() async {
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

  test_class_staticGetter_expressionBody_staticSetter_blockBody_augmentation_staticField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  static set foo(int _) {}
  augment static abstract int foo;
}
''');
  }

  test_class_staticGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static int get foo;
}
''');
  }

  test_class_staticGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  external static int get foo;
}
''');
  }

  test_class_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_staticGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_class_staticGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
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

  test_class_staticGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
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

  test_class_staticMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
''');
  }

  test_class_staticMethod_blockBody_augmentation_blockBody() async {
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

  test_class_staticMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static void foo() {}
}
''');
  }

  test_class_staticMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static void foo();
}
''');
  }

  test_class_staticMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  external static void foo();
}
''');
  }

  test_class_staticMethod_nativeBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo(_) native 'string';
//                  ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_class_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_staticMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_class_staticMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_class_staticMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_staticSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
''');
  }

  test_class_staticSetter_blockBody_augmentation_blockBody() async {
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

  test_class_staticSetter_blockBody_augmentation_staticField() async {
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

  test_class_staticSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static set foo(int _) {}
}
''');
  }

  test_class_staticSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external static set foo(int _);
}
''');
  }

  test_class_staticSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  external static set foo(int _);
}
''');
  }

  test_class_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_staticSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_class_staticSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_class_staticSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract int foo;
//             ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
}
''');
  }

  test_enum_instanceField_abstract_augmentation_instanceGetter_expressionBody_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract int foo;
  augment int get foo => 0;
  augment void set foo(int _) {}
}
''');
  }

  test_enum_instanceField_abstract_augmentation_instanceGetter_expressionBody_instanceSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract int foo;
//             ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
  augment int get foo => 0;
  augment void set foo(int _);
}
''');
  }

  test_enum_instanceField_abstract_augmentation_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract int foo;
//             ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment void set foo(int _) {}
}
''');
  }

  test_enum_instanceField_abstract_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  abstract int foo;
//             ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_enum_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
}
''');
  }

  test_enum_instanceField_abstractFinal_augmentation_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment abstract final int foo;
}
''');
  }

  test_enum_instanceField_abstractFinal_augmentation_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract final int foo;
  augment int get foo => 0;
}
''');
  }

  test_enum_instanceField_abstractFinal_augmentation_instanceGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment int get foo;
}
''');
  }

  test_enum_instanceField_external() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external int foo;
}
''');
  }

  test_enum_instanceField_externalFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external final int foo;
}
''');
  }

  test_enum_instanceGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo;
//^^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_enum_instanceMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo();
//^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_enum_instanceSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_enum_staticGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_enum_staticGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static int get foo => 0;
}
''');
  }

  test_enum_staticGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_staticGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  external static int get foo;
}
''');
  }

  test_enum_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_staticGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_enum_staticGetter_noBody_augmentation_noBody() async {
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

  test_enum_staticGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_staticMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_enum_staticMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static void foo() {}
}
''');
  }

  test_enum_staticMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_staticMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  external static void foo();
}
''');
  }

  test_enum_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_staticMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_enum_staticMethod_noBody_augmentation_noBody() async {
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

  test_enum_staticMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_staticSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_enum_staticSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static set foo(int _) {}
}
''');
  }

  test_enum_staticSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_staticSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  external static set foo(int _);
}
''');
  }

  test_enum_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_staticSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_enum_staticSetter_noBody_augmentation_noBody() async {
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

  test_enum_staticSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
enum E {
  v;
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int foo;
//             ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
}
''');
  }

  test_extension_instanceField_abstract_augmentation_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int foo;
//             ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
  augment int get foo => 0;
}
''');
  }

  test_extension_instanceField_abstract_augmentation_instanceGetter_expressionBody_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int foo;
  augment int get foo => 0;
  augment set foo(int _) {}
}
''');
  }

  test_extension_instanceField_abstract_augmentation_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int foo;
//             ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment set foo(int _) {}
}
''');
  }

  test_extension_instanceField_abstract_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  abstract int foo;
//             ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_extension_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
}
''');
  }

  test_extension_instanceField_abstractFinal_augmentation_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int foo;
  augment int get foo => 0;
}
''');
  }

  test_extension_instanceField_abstractFinal_augmentation_instanceGetter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int foo;
  augment external int get foo;
}
''');
  }

  test_extension_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}
''');
  }

  test_extension_instanceGetter_expressionBody_augmentation_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  augment abstract final int foo;
}
''');
  }

  test_extension_instanceGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  int get foo => 0;
}
''');
  }

  test_extension_instanceGetter_expressionBody_instanceSetter_blockBody_augmentation_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
  augment abstract int foo;
}
''');
  }

  test_extension_instanceGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_instanceGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external int get foo;
}
''');
  }

  test_extension_instanceGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
//        ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
  augment int get foo => 0;
}
''');
  }

  test_extension_instanceGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
//        ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment int get foo;
}
''');
  }

  test_extension_instanceGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  int get foo;
//        ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}
''');
  }

  test_extension_instanceMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  void foo() {}
}
''');
  }

  test_extension_instanceMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external void foo();
}
''');
  }

  test_extension_instanceMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external void foo();
}
''');
  }

  test_extension_instanceMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
//     ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
  augment void foo() {}
}
''');
  }

  test_extension_instanceMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo();
//     ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment void foo();
}
''');
  }

  test_extension_instanceMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  void foo();
//     ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceOperator_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int operator -(int _);
//             ^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceOperator_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int operator -(int _);
//             ^
// [diag.functionNotCompleteAfterAugmentations] The function or member '-' must have a body after all augmentations are applied.
  augment int operator -(int _);
}
''');
  }

  test_extension_instanceOperator_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  int operator -(int _);
//             ^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}
''');
  }

  test_extension_instanceSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  set foo(int _) {}
}
''');
  }

  test_extension_instanceSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_instanceSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external set foo(int _);
}
''');
  }

  test_extension_instanceSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
//    ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_instanceSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
  augment set foo(int _) {}
}
''');
  }

  test_extension_instanceSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _);
//    ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment set foo(int _);
}
''');
  }

  test_extension_instanceSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  set foo(int _);
//    ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_extension_staticGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}
''');
  }

  test_extension_staticGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static int get foo => 0;
}
''');
  }

  test_extension_staticGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_staticGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external static int get foo;
}
''');
  }

  test_extension_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_staticGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_extension_staticGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_extension_staticGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_staticMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {}
}
''');
  }

  test_extension_staticMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static void foo() {}
}
''');
  }

  test_extension_staticMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_staticMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external static void foo();
}
''');
  }

  test_extension_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_staticMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_extension_staticMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_extension_staticMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_staticSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _) {}
}
''');
  }

  test_extension_staticSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static set foo(int _) {}
}
''');
  }

  test_extension_staticSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_staticSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  external static set foo(int _);
}
''');
  }

  test_extension_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extension_staticSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_extension_staticSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_extension_staticSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension E on int {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract int foo;
//             ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
}
''');
  }

  test_extensionType_instanceField_abstract_augmentation_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract int foo;
//             ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
  augment int get foo => 0;
}
''');
  }

  test_extensionType_instanceField_abstract_augmentation_instanceGetter_expressionBody_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract int foo;
  augment int get foo => 0;
  augment set foo(int _) {}
}
''');
  }

  test_extensionType_instanceField_abstract_augmentation_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract int foo;
//             ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
  augment set foo(int _) {}
}
''');
  }

  test_extensionType_instanceField_abstract_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  abstract int foo;
//             ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  test_extensionType_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
}
''');
  }

  test_extensionType_instanceField_abstractFinal_augmentation_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract final int foo;
  augment int get foo => 0;
}
''');
  }

  test_extensionType_instanceField_abstractFinal_augmentation_instanceGetter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  abstract final int foo;
  augment external int get foo;
}
''');
  }

  test_extensionType_instanceField_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external int foo;
}
''');
  }

  test_extensionType_instanceGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo => 0;
}
''');
  }

  test_extensionType_instanceGetter_expressionBody_augmentation_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo => 0;
  augment abstract final int foo;
}
''');
  }

  test_extensionType_instanceGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  int get foo => 0;
}
''');
  }

  test_extensionType_instanceGetter_expressionBody_instanceSetter_blockBody_augmentation_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo => 0;
  set foo(int _) {}
  augment abstract int foo;
}
''');
  }

  test_extensionType_instanceGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_instanceGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external int get foo;
}
''');
  }

  test_extensionType_instanceGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
//^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_instanceGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
  augment int get foo => 0;
}
''');
  }

  test_extensionType_instanceGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  int get foo;
//        ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment int get foo;
}
''');
  }

  test_extensionType_instanceGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  int get foo;
//^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_instanceMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo() {}
}
''');
  }

  test_extensionType_instanceMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  void foo() {}
}
''');
  }

  test_extensionType_instanceMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_instanceMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external void foo();
}
''');
  }

  test_extensionType_instanceMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
//^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_instanceMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
  augment void foo() {}
}
''');
  }

  test_extensionType_instanceMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  void foo();
//     ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment void foo();
}
''');
  }

  test_extensionType_instanceMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  void foo();
//^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_instanceSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _) {}
}
''');
  }

  test_extensionType_instanceSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  set foo(int _) {}
}
''');
  }

  test_extensionType_instanceSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_instanceSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external set foo(int _);
}
''');
  }

  test_extensionType_instanceSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_instanceSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
  augment set foo(int _) {}
}
''');
  }

  test_extensionType_instanceSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  set foo(int _);
//    ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment set foo(int _);
}
''');
  }

  test_extensionType_instanceSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'E' is an extension type.
}
''');
  }

  test_extensionType_staticGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo => 0;
}
''');
  }

  test_extensionType_staticGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static int get foo => 0;
}
''');
  }

  test_extensionType_staticGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_staticGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external static int get foo;
}
''');
  }

  test_extensionType_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_staticGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_extensionType_staticGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_extensionType_staticGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_staticMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo() {}
}
''');
  }

  test_extensionType_staticMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static void foo() {}
}
''');
  }

  test_extensionType_staticMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_staticMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external static void foo();
}
''');
  }

  test_extensionType_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_staticMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_extensionType_staticMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_extensionType_staticMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_staticSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _) {}
}
''');
  }

  test_extensionType_staticSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static set foo(int _) {}
}
''');
  }

  test_extensionType_staticSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_staticSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  external static set foo(int _);
}
''');
  }

  test_extensionType_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_staticSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_extensionType_staticSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_extensionType_staticSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
extension type E(int i) {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_localFunction_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo() {}
  foo();
}
''');
  }

  test_mixin_staticGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
}
''');
  }

  test_mixin_staticGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static int get foo => 0;
}
''');
  }

  test_mixin_staticGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_staticGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  external static int get foo;
}
''');
  }

  test_mixin_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_staticGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
  augment static int get foo => 0;
}
''');
  }

  test_mixin_staticGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo;
//               ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static int get foo;
}
''');
  }

  test_mixin_staticGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_staticMethod_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
}
''');
  }

  test_mixin_staticMethod_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static void foo() {}
}
''');
  }

  test_mixin_staticMethod_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_staticMethod_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  external static void foo();
}
''');
  }

  test_mixin_staticMethod_nativeBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static int foo(_) native 'string';
//                  ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_mixin_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_staticMethod_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
  augment static void foo() {}
}
''');
  }

  test_mixin_staticMethod_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo();
//            ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static void foo();
}
''');
  }

  test_mixin_staticMethod_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_staticSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _) {}
}
''');
  }

  test_mixin_staticSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static set foo(int _) {}
}
''');
  }

  test_mixin_staticSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_staticSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  external static set foo(int _);
}
''');
  }

  test_mixin_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_mixin_staticSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
  augment static set foo(int _) {}
}
''');
  }

  test_mixin_staticSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _);
//           ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
  augment static set foo(int _);
}
''');
  }

  test_mixin_staticSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
mixin M {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_topLevelFunction_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
''');
  }

  test_topLevelFunction_blockBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
//   ^^^
// [context 1] The complete declaration is here.
augment void foo() {}
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevelFunction_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
void foo() {}
''');
  }

  test_topLevelFunction_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() {}
//                  ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevelFunction_external_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
external void foo() {}
//                  ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevelFunction_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() => null;
//                  ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevelFunction_external_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
external void foo() => null;
//                  ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevelFunction_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo();
''');
  }

  test_topLevelFunction_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
external void foo();
''');
  }

  test_topLevelFunction_nativeBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo(_) native 'string';
//         ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_topLevelFunction_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
//        ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelFunction_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
augment void foo() {}
''');
  }

  test_topLevelFunction_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo();
//   ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment void foo();
''');
  }

  test_topLevelFunction_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
void foo();
//        ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
''');
  }

  test_topLevelGetter_expressionBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The complete declaration is here.
augment int get foo => 1;
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevelGetter_expressionBody_augmentation_topLevelVariable() async {
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

  test_topLevelGetter_expressionBody_augmentation_topLevelVariable_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
augment abstract final int foo;
''');
  }

  test_topLevelGetter_expressionBody_augmentation_topLevelVariable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The complete declaration is here.
augment final int foo = 1;
//                ^^^
// [diag.augmentationInducedGetterAlreadyComplete][context 1] The getter induced by this augmentation is complete, but the getter being augmented is already complete.
''');
  }

  test_topLevelGetter_expressionBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
int get foo => 0;
''');
  }

  test_topLevelGetter_expressionBody_topLevelSetter_blockBody_augmentation_topLevelVariable() async {
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

  test_topLevelGetter_expressionBody_topLevelSetter_blockBody_augmentation_topLevelVariable_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
set foo(int _) {}
augment abstract int foo;
''');
  }

  test_topLevelGetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external int get foo;
''');
  }

  test_topLevelGetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
external int get foo;
''');
  }

  test_topLevelGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelGetter_noBody_augmentation_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
augment int get foo => 0;
''');
  }

  test_topLevelGetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
//      ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment int get foo;
''');
  }

  test_topLevelGetter_noBody_augmentation_topLevelVariable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
augment final int foo = 1;
''');
  }

  test_topLevelGetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelGetter_noBody_topLevelSetter_noBody_augmentation_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo;
set foo(int _);
augment int foo = 1;
''');
  }

  test_topLevelSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
''');
  }

  test_topLevelSetter_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) async {}
//             ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }

  test_topLevelSetter_blockBody_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) async* {}
//             ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }

  test_topLevelSetter_blockBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
//  ^^^
// [context 1] The complete declaration is here.
augment set foo(int _) {}
// [diag.functionAlreadyComplete][column 1][length 7][context 1] The augmentation can't provide a body because the function or member is already complete.
''');
  }

  test_topLevelSetter_blockBody_augmentation_topLevelVariable() async {
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

  test_topLevelSetter_blockBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
set foo(int _) {}
''');
  }

  test_topLevelSetter_blockBody_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) sync* {}
//             ^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }

  test_topLevelSetter_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external set foo(int _);
''');
  }

  test_topLevelSetter_external_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
external set foo(int _);
''');
  }

  test_topLevelSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelSetter_noBody_augmentation_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
augment set foo(int _) {}
''');
  }

  test_topLevelSetter_noBody_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
//  ^^^
// [diag.functionNotCompleteAfterAugmentations] The function or member 'foo' must have a body after all augmentations are applied.
augment set foo(int _);
''');
  }

  test_topLevelSetter_noBody_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
set foo(int _);
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  test_topLevelVariable_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
''');
  }

  test_topLevelVariable_abstract_augmentation_topLevelGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
augment int get foo => 0;
''');
  }

  test_topLevelVariable_abstract_augmentation_topLevelGetter_expressionBody_augmentation_topLevelSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
augment int get foo => 0;
augment set foo(int _) {}
''');
  }

  test_topLevelVariable_abstract_augmentation_topLevelSetter_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract int foo;
//           ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
augment set foo(int _) {}
''');
  }

  test_topLevelVariable_abstract_beforeAugmentations() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: augmentations
abstract int foo;
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');
  }

  test_topLevelVariable_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
//                 ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
''');
  }

  test_topLevelVariable_abstractFinal_augmentation_topLevelGetter_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
augment int get foo => 0;
''');
  }

  test_topLevelVariable_abstractFinal_augmentation_topLevelVariable_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
//                 ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
augment abstract final int foo;
''');
  }
}
