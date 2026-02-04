// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorBodyTest);
  });
}

@reflectiveTest
class ConstructorBodyTest extends PubPackageResolutionTest {
  test_class_primaryConstructor_const_blockBody() async {
    await assertErrorsInCode(
      r'''
class const C() {
  this {}
}
''',
      [error(diag.constConstructorWithBody, 25, 1)],
    );
  }

  test_class_primaryConstructor_const_emptyBody() async {
    await assertNoErrorsInCode(r'''
class const C() {
  this;
}
''');
  }

  test_class_primaryConstructor_const_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
class const C() {
  this : assert(true);
}
''');
  }

  test_class_primaryConstructor_const_expressionBody() async {
    await assertErrorsInCode(
      r'''
class const C() {
  this => null;
}
''',
      [
        error(diag.expectedIdentifierButGotKeyword, 20, 4),
        error(diag.missingMethodParameters, 20, 4),
      ],
    );
  }

  test_class_primaryConstructor_const_noBody() async {
    await assertNoErrorsInCode(r'''
class const C() {}
''');
  }

  test_class_secondaryConstructor_constFactory_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
  const factory C.named() {
    return const C();
  }
}
''',
      [error(diag.constFactory, 25, 5)],
    );
  }

  test_class_secondaryConstructor_constFactory_emptyBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const factory C();
}
''',
      [error(diag.constFactory, 12, 5), error(diag.missingFunctionBody, 29, 1)],
    );
  }

  test_class_secondaryConstructor_constFactory_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const factory C() => null;
}
''',
      [
        error(diag.constFactory, 12, 5),
        error(diag.returnOfInvalidTypeFromConstructor, 33, 4),
      ],
    );
  }

  test_class_secondaryConstructor_constFactory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external const factory C() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 35, 1),
        error(diag.externalFactoryWithBody, 39, 1),
      ],
    );
  }

  test_class_secondaryConstructor_constFactory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  external const factory C();
}
''');
  }

  test_class_secondaryConstructor_constFactory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external const factory C() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 39, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 42, 4),
      ],
    );
  }

  test_class_secondaryConstructor_constFactory_redirecting() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
  const factory C.named() = C;
}
''');
  }

  test_class_secondaryConstructor_constFactory_redirecting_unresolved() async {
    await assertErrorsInCode(
      r'''
class C {
  const factory C.named() = Unresolved;
}
''',
      [error(diag.redirectToNonClass, 38, 10)],
    );
  }

  test_class_secondaryConstructor_constGenerative_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C() {}
}
''',
      [error(diag.constConstructorWithBody, 22, 1)],
    );
  }

  test_class_secondaryConstructor_constGenerative_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
}
''');
  }

  test_class_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
class C {
  const C() : assert(true);
}
''');
  }

  test_class_secondaryConstructor_constGenerative_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
  const C.named() => C();
}
''',
      [
        error(diag.constConstructorWithBody, 41, 2),
        error(diag.returnInGenerativeConstructor, 41, 7),
      ],
    );
  }

  test_class_secondaryConstructor_constGenerative_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external const C() {}
}
''',
      [
        error(diag.externalMethodWithBody, 31, 1),
        error(diag.constConstructorWithBody, 31, 1),
      ],
    );
  }

  test_class_secondaryConstructor_constGenerative_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  external const C();
}
''');
  }

  test_class_secondaryConstructor_constGenerative_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external const C() => null;
}
''',
      [
        error(diag.externalMethodWithBody, 31, 2),
        error(diag.constConstructorWithBody, 31, 2),
        error(diag.returnInGenerativeConstructor, 31, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 34, 4),
      ],
    );
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
  const C.named() : this() {}
}
''',
      [
        error(diag.redirectingConstructorWithBody, 50, 1),
        error(diag.constConstructorWithBody, 50, 1),
      ],
    );
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
  const C.named() : this();
}
''');
  }

  test_class_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
  const C.named() : this() => null;
}
''',
      [
        error(diag.redirectingConstructorWithBody, 50, 2),
        error(diag.constConstructorWithBody, 50, 2),
        error(diag.returnInGenerativeConstructor, 50, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 53, 4),
      ],
    );
  }

  test_class_secondaryConstructor_factory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external factory C() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 29, 1),
        error(diag.externalFactoryWithBody, 33, 1),
      ],
    );
  }

  test_class_secondaryConstructor_factory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  external factory C();
}
''');
  }

  test_class_secondaryConstructor_factory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external factory C() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 33, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 36, 4),
      ],
    );
  }

  test_class_secondaryConstructor_generative_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external C() {}
}
''',
      [error(diag.externalMethodWithBody, 25, 1)],
    );
  }

  test_class_secondaryConstructor_generative_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
class C {
  external C();
}
''');
  }

  test_class_secondaryConstructor_generative_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class C {
  external C() => null;
}
''',
      [
        error(diag.externalMethodWithBody, 25, 2),
        error(diag.returnInGenerativeConstructor, 25, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 28, 4),
      ],
    );
  }

  test_enum_primaryConstructor_const_blockBody() async {
    await assertErrorsInCode(
      r'''
enum const E() {
  v;
  this {}
}
''',
      [error(diag.constConstructorWithBody, 29, 1)],
    );
  }

  test_enum_primaryConstructor_const_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
  this;
}
''');
  }

  test_enum_primaryConstructor_const_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
  this : assert(true);
}
''');
  }

  test_enum_primaryConstructor_const_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum const E() {
  v;
  this => null;
}
''',
      [
        error(diag.expectedIdentifierButGotKeyword, 24, 4),
        error(diag.missingMethodParameters, 24, 4),
      ],
    );
  }

  test_enum_primaryConstructor_const_noBody() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
}
''');
  }

  test_enum_secondaryConstructor_constFactory_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  const factory E.named() {
    return v;
  }
}
''',
      [error(diag.constFactory, 29, 5)],
    );
  }

  test_enum_secondaryConstructor_constFactory_emptyBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  const factory E.named();
}
''',
      [error(diag.constFactory, 29, 5), error(diag.missingFunctionBody, 52, 1)],
    );
  }

  test_enum_secondaryConstructor_constFactory_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  const factory E.named() => null;
}
''',
      [
        error(diag.constFactory, 29, 5),
        error(diag.returnOfInvalidTypeFromConstructor, 56, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_constFactory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  external const factory E.named() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 52, 7),
        error(diag.externalFactoryWithBody, 62, 1),
      ],
    );
  }

  test_enum_secondaryConstructor_constFactory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
  external const factory E.named();
}
''');
  }

  test_enum_secondaryConstructor_constFactory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  external const factory E.named() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 62, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 65, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_constFactory_redirecting() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  const factory E.named() = E;
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 55, 1)],
    );
  }

  test_enum_secondaryConstructor_constGenerative_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() {}
}
''',
      [error(diag.constConstructorWithBody, 26, 1)],
    );
  }

  test_enum_secondaryConstructor_constGenerative_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E() : assert(true);
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  const E.named() => null;
}
''',
      [
        error(diag.unusedElement, 37, 5),
        error(diag.constConstructorWithBody, 45, 2),
        error(diag.returnInGenerativeConstructor, 45, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 48, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_constGenerative_external_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  external const E() {}
}
''',
      [
        error(diag.externalMethodWithBody, 35, 1),
        error(diag.constConstructorWithBody, 35, 1),
      ],
    );
  }

  test_enum_secondaryConstructor_constGenerative_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  external const E();
}
''');
  }

  test_enum_secondaryConstructor_constGenerative_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  external const E() => null;
}
''',
      [
        error(diag.externalMethodWithBody, 35, 2),
        error(diag.constConstructorWithBody, 35, 2),
        error(diag.returnInGenerativeConstructor, 35, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 38, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this() {}
}
''',
      [
        error(diag.redirectingConstructorWithBody, 67, 1),
        error(diag.constConstructorWithBody, 67, 1),
      ],
    );
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this();
}
''');
  }

  test_enum_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v1, v2.named();
  const E();
  const E.named() : this() => null;
}
''',
      [
        error(diag.redirectingConstructorWithBody, 67, 2),
        error(diag.constConstructorWithBody, 67, 2),
        error(diag.returnInGenerativeConstructor, 67, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 70, 4),
      ],
    );
  }

  test_enum_secondaryConstructor_factory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  external factory E.named() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 46, 7),
        error(diag.externalFactoryWithBody, 56, 1),
      ],
    );
  }

  test_enum_secondaryConstructor_factory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
  external factory E.named();
}
''');
  }

  test_enum_secondaryConstructor_factory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  external factory E.named() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 56, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 59, 4),
      ],
    );
  }

  test_extensionType_primaryConstructor_const_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  this {}
}
''',
      [error(diag.constConstructorWithBody, 40, 1)],
    );
  }

  test_extensionType_primaryConstructor_const_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  this;
}
''');
  }

  test_extensionType_primaryConstructor_const_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  this : assert(true);
}
''');
  }

  test_extensionType_primaryConstructor_const_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  this => null;
}
''',
      [
        error(diag.expectedIdentifierButGotKeyword, 35, 4),
        error(diag.missingFunctionParameters, 35, 4),
      ],
    );
  }

  test_extensionType_primaryConstructor_const_noBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const factory E.named() {
    return const E(0);
  }
}
''',
      [error(diag.constFactory, 35, 5)],
    );
  }

  test_extensionType_secondaryConstructor_constFactory_emptyBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const factory E.named();
}
''',
      [error(diag.constFactory, 35, 5), error(diag.missingFunctionBody, 58, 1)],
    );
  }

  test_extensionType_secondaryConstructor_constFactory_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const factory E.named() => null;
}
''',
      [
        error(diag.constFactory, 35, 5),
        error(diag.returnOfInvalidTypeFromConstructor, 62, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constFactory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external const factory E.named() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 58, 7),
        error(diag.externalFactoryWithBody, 68, 1),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constFactory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  external const factory E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_constFactory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external const factory E.named() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 68, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 71, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constFactory_redirecting() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  const factory E.named(int i) = E;
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const E.named() : it = 0 {}
}
''',
      [error(diag.constConstructorWithBody, 60, 1)],
    );
  }

  test_extensionType_secondaryConstructor_constGenerative_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  const E.named() : it = 0;
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_emptyBody_hasAssert() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  const E.named() : it = 0, assert(true);
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const E.named() : it = 0 => E(0);
}
''',
      [
        error(diag.constConstructorWithBody, 60, 2),
        error(diag.returnInGenerativeConstructor, 60, 8),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constGenerative_external_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external const E.named() {}
}
''',
      [
        error(diag.externalMethodWithBody, 60, 1),
        error(diag.constConstructorWithBody, 60, 1),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constGenerative_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  external const E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerative_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external const E.named() => null;
}
''',
      [
        error(diag.externalMethodWithBody, 60, 2),
        error(diag.constConstructorWithBody, 60, 2),
        error(diag.returnInGenerativeConstructor, 60, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 63, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const E.named() : this(0) {}
}
''',
      [
        error(diag.redirectingConstructorWithBody, 61, 1),
        error(diag.constConstructorWithBody, 61, 1),
      ],
    );
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  const E.named() : this(0);
}
''');
  }

  test_extensionType_secondaryConstructor_constGenerativeRedirecting_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  const E.named() : this(0) => null;
}
''',
      [
        error(diag.redirectingConstructorWithBody, 61, 2),
        error(diag.constConstructorWithBody, 61, 2),
        error(diag.returnInGenerativeConstructor, 61, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 64, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_factory_external_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external factory E.named() {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 52, 7),
        error(diag.externalFactoryWithBody, 62, 1),
      ],
    );
  }

  test_extensionType_secondaryConstructor_factory_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  external factory E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_factory_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  external factory E.named() => null;
}
''',
      [
        error(diag.externalFactoryWithBody, 62, 2),
        error(diag.returnOfInvalidTypeFromConstructor, 65, 4),
      ],
    );
  }

  test_extensionType_secondaryConstructor_generative_external_blockBody() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  external E.named() {}
}
''',
      [error(diag.externalMethodWithBody, 48, 1)],
    );
  }

  test_extensionType_secondaryConstructor_generative_external_emptyBody() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  external E.named();
}
''');
  }

  test_extensionType_secondaryConstructor_generative_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  external E.named() => null;
}
''',
      [
        error(diag.externalMethodWithBody, 48, 2),
        error(diag.returnInGenerativeConstructor, 48, 8),
        error(diag.returnOfInvalidTypeFromConstructor, 51, 4),
      ],
    );
  }
}
