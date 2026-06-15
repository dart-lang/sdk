// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorBodyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorBodyTest extends PubPackageResolutionTest {
  test_class_primaryConstructor_const_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class const C() {
  this {}
//     ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_class_primaryConstructor_const_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class const C() {
  this;
}
''');
  }

  test_class_primaryConstructor_const_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class const C() {
  this : assert(true);
}
''');
  }

  test_class_primaryConstructor_const_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class const C() {
  this => null;
//     ^^
// [diag.constPrimaryConstructorWithExpressionBody] The body part of a constant primary constructor can't have an expression body.
}
''');
  }

  test_class_primaryConstructor_const_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class const C() {}
''');
  }

  test_class_primaryConstructor_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this => 0;
//     ^^
// [diag.primaryConstructorBodyWithExpressionBody] A primary constructor body can't use '=>'.
}
''');
  }

  test_class_primaryConstructor_modifier_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this async {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async'.
}
''');
  }

  test_class_primaryConstructor_modifier_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this async* {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async*'.
}
''');
  }

  test_class_primaryConstructor_modifier_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this sync* {}
//     ^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'sync*'.
}
''');
  }

  test_class_secondaryConstructor_constFactory_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const factory C.named() {
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
    return const C();
  }
}
''');
  }

  test_class_secondaryConstructor_constFactory_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const factory C();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//              ^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_class_secondaryConstructor_constFactory_emptyBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  const factory C();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_secondaryConstructor_constFactory_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const factory C() => null;
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                     ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_constFactory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const factory C() {}
//                       ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'C', is a potentially non-nullable type.
//                           ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_class_secondaryConstructor_constFactory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const factory C();
}
''');
  }

  test_class_secondaryConstructor_constFactory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const factory C() => null;
//                           ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                              ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_constFactory_redirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const factory C.named() = C;
}
''');
  }

  test_class_secondaryConstructor_constFactory_redirecting_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const factory C.named() = Unresolved;
//                          ^^^^^^^^^^
// [diag.redirectToNonClass] The name 'Unresolved' isn't a type and can't be used in a redirected constructor.
}
''');
  }

  test_class_secondaryConstructor_constGenerative_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C() {}
//          ^
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_class_secondaryConstructor_constGenerative_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
}
''');
  }

  test_class_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C() : assert(true);
}
''');
  }

  test_class_secondaryConstructor_constGenerative_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const C.named() => C();
//                ^^
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                ^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
}
''');
  }

  test_class_secondaryConstructor_constGenerative_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const C() {}
//                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_class_secondaryConstructor_constGenerative_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const C();
}
''');
  }

  test_class_secondaryConstructor_constGenerative_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external const C() => null;
//                   ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                   ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                      ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const C.named() : this() {}
//                         ^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const C.named() : this();
}
''');
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  const C.named() : this() => null;
//                         ^^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                         ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                            ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C.named' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_factory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external factory C() {}
//                 ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'C', is a potentially non-nullable type.
//                     ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_class_secondaryConstructor_factory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external factory C();
}
''');
  }

  test_class_secondaryConstructor_factory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external factory C() => null;
//                     ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                        ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_named_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory named();
  augment factory named() => throw 0;
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_named_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory named();
//^^^^^^^^^^^^^
// [diag.factoryNotCompleteAfterAugmentations] The factory constructor 'named' must have a body or redirection after all augmentations are applied.
  augment factory named();
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_named_external_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external factory named();
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_named_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory named() => throw 0;
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_named_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory named();
//^^^^^^^^^^^^^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_unnamed_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory ();
//^^^^^^^
// [diag.factoryNotCompleteAfterAugmentations] The factory constructor 'new' must have a body or redirection after all augmentations are applied.
  augment factory ();
}
''');
  }

  test_class_secondaryConstructor_factory_factoryHead_unnamed_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory ();
//^^^^^^^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_named_augmentation_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named();
//        ^^^^^^^
// [diag.factoryNotCompleteAfterAugmentations] The factory constructor 'named' must have a body or redirection after all augmentations are applied.
  augment factory A.named();
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_named_external_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  external factory A.named();
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_named_hasBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  factory A.named() => throw 0;
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_named_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named();
//        ^^^^^^^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_named_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  factory A.named();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_unnamed_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A._();
  factory A();
  augment factory A() => A._();
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_unnamed_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A._();
  factory A() => A._();
//        ^
// [context 1] The complete declaration is here.
  augment factory A() => A._();
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_unnamed_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A();
//        ^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_unnamed_noBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  factory A();
//           ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_class_secondaryConstructor_factory_typeName_unnamed_redirecting_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A._();
  factory A() = A._;
//        ^
// [context 1] The complete declaration is here.
  augment factory A() => A._();
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external C() {}
//             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_secondaryConstructor_generative_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external C();
}
''');
  }

  test_class_secondaryConstructor_generative_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external C() => null;
//             ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
//             ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_assertInitializer_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : assert(true);
//^
// [context 1] The complete declaration is here.
  augment A() {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  augment A() {}
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_augmentation_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  augment A() {}
//        ^
// [context 1] The complete declaration is here.
  augment A() {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_fieldFormalParameter_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A(this.x);
//^
// [context 1] The complete declaration is here.
  augment A(int x) {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_fieldInitializer_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A() : x = 0;
//^
// [context 1] The complete declaration is here.
  augment A() {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_hasBody_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
//^
// [context 1] The complete declaration is here.
  augment A() {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_secondaryConstructor_generative_unnamed_superFormalParameter_augmentation_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x);
}
class B extends A {
  B(super.x);
//^
// [context 1] The complete declaration is here.
  augment B(int x) {}
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
//        ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_enum_primaryConstructor_const_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E() {
  v;
  this {}
//     ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_enum_primaryConstructor_const_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E() {
  v;
  this;
}
''');
  }

  test_enum_primaryConstructor_const_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E() {
  v;
  this : assert(true);
}
''');
  }

  test_enum_primaryConstructor_const_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E() {
  v;
  this => null;
//     ^^
// [diag.constPrimaryConstructorWithExpressionBody] The body part of a constant primary constructor can't have an expression body.
}
''');
  }

  test_enum_primaryConstructor_const_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E() {
  v;
}
''');
  }

  test_enum_primaryConstructor_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this => 0;
//     ^^
// [diag.constPrimaryConstructorWithExpressionBody] The body part of a constant primary constructor can't have an expression body.
}
''');
  }

  test_enum_primaryConstructor_modifier_async() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this async {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async'.
//           ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_enum_primaryConstructor_modifier_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this async* {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async*'.
//            ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_enum_primaryConstructor_modifier_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this sync* {}
//     ^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'sync*'.
//           ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const factory E.named() {
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
    return v;
  }
}
''');
  }

  test_enum_secondaryConstructor_constFactory_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const factory E.named();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//              ^^^^^^^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_emptyBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
enum E {
  v;
  const E();
  const factory E.named();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const factory E.named() => null;
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                           ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external const factory E.named() {}
//                       ^^^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'E', is a potentially non-nullable type.
//                                 ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external const factory E.named();
}
''');
  }

  test_enum_secondaryConstructor_constFactory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external const factory E.named() => null;
//                                 ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                                    ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_enum_secondaryConstructor_constFactory_redirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const factory E.named() = E;
//                          ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() {}
//          ^
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() : assert(true);
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const E.named() => null;
//        ^^^^^
// [diag.unusedElement] The declaration 'E.named' isn't referenced.
//                ^^
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                   ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external const E() {}
//                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external const E();
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external const E() => null;
//                   ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                   ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                      ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E' because it has a return type of 'E'.
}
''');
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this() {}
//                         ^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this();
}
''');
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this() => null;
//                         ^^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                         ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                            ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_enum_secondaryConstructor_factory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external factory E.named() {}
//                 ^^^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'E', is a potentially non-nullable type.
//                           ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_enum_secondaryConstructor_factory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external factory E.named();
}
''');
  }

  test_enum_secondaryConstructor_factory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  external factory E.named() => null;
//                           ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                              ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_primaryConstructor_const_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  this {}
//     ^
// [diag.constPrimaryConstructorWithBlockBody] The body part of a constant primary constructor can't have a block body.
}
''');
  }

  test_extensionType_primaryConstructor_const_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  this;
}
''');
  }

  test_extensionType_primaryConstructor_const_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  this : assert(true);
}
''');
  }

  test_extensionType_primaryConstructor_const_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  this => null;
//     ^^
// [diag.constPrimaryConstructorWithExpressionBody] The body part of a constant primary constructor can't have an expression body.
}
''');
  }

  test_extensionType_primaryConstructor_const_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}
''');
  }

  test_extensionType_primaryConstructor_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int x) {
  this => 0;
//     ^^
// [diag.primaryConstructorBodyWithExpressionBody] A primary constructor body can't use '=>'.
}
''');
  }

  test_extensionType_primaryConstructor_modifier_async() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int x) {
  this async {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async'.
}
''');
  }

  test_extensionType_primaryConstructor_modifier_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int x) {
  this async* {}
//     ^^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'async*'.
}
''');
  }

  test_extensionType_primaryConstructor_modifier_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int x) {
  this sync* {}
//     ^^^^
// [diag.primaryConstructorBodyWithModifier] A primary constructor body can't have the modifier 'sync*'.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const factory E.named() {
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
    return const E(0);
  }
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const factory E.named();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//              ^^^^^^^
// [diag.factoryWithoutBody] A non-redirecting 'factory' constructor must have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_emptyBody_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type const E(int it) {
  const factory E.named();
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const factory E.named() => null;
//^^^^^
// [diag.constFactory] Only redirecting factory constructors can be declared to be 'const'.
//                           ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const factory E.named() {}
//                       ^^^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'E', is a potentially non-nullable type.
//                                 ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const factory E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const factory E.named() => null;
//                                 ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                                    ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_redirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const factory E.named(int i) = E;
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : it = 0 {}
//                         ^
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : it = 0;
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : it = 0, assert(true);
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : it = 0 => E(0);
//                         ^^
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                         ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const E.named() {}
//                         ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external const E.named() => null;
//                         ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                         ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                            ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : this(0) {}
//                          ^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : this(0);
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  const E.named() : this(0) => null;
//                          ^^
// [diag.redirectingConstructorWithBody] Redirecting constructors can't have a body.
// [diag.constConstructorWithBody] Const constructors can't have a body.
//                          ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                             ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_secondaryConstructor_factory_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external factory E.named() {}
//                 ^^^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'E', is a potentially non-nullable type.
//                           ^
// [diag.externalFactoryWithBody] External factories can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_factory_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external factory E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_factory_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {
  external factory E.named() => null;
//                           ^^
// [diag.externalFactoryWithBody] External factories can't have a body.
//                              ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  external E.named() {}
//                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_extensionType_secondaryConstructor_generative_external_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  external E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_generative_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  external E.named() => null;
//                   ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
//                   ^^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//                      ^^^^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'Null' can't be returned from the constructor 'E.named' because it has a return type of 'E'.
}
''');
  }
}
