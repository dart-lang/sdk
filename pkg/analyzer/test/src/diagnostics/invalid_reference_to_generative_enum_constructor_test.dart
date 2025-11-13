// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidReferenceToGenerativeEnumConstructorTest);
  });
}

@reflectiveTest
class InvalidReferenceToGenerativeEnumConstructorTest
    extends PubPackageResolutionTest {
  test_factory_named() async {
    await assertNoErrorsInCode('''
enum E {
  v();

  factory E.named() => v;
}

void f() {
  E.named;
  E.named();
}
''');
  }

  test_factory_unnamed() async {
    await assertNoErrorsInCode('''
enum E {
  v.named();

  const E.named();
  factory E() => v;
}

void f() {
  E.new;
  E();
}
''');
  }

  test_generative_named_constructorReference() async {
    await assertErrorsInCode(
      '''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named;
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 58, 7)],
    );
  }

  test_generative_named_instanceCreation_implicitNew() async {
    await assertErrorsInCode(
      '''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named();
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 58, 7)],
    );
  }

  test_generative_named_redirectingConstructorInvocation() async {
    await assertNoErrorsInCode('''
enum E {
  v;

  const E() : this.named();
  const E.named();
}
''');
  }

  test_generative_named_redirectingFactory() async {
    await assertErrorsInCode(
      '''
enum E {
  v;

  const factory E() = E.named;
  const E.named();
}
''',
      [
        error(diag.enumConstantInvokesFactoryConstructor, 11, 1),
        error(diag.invalidReferenceToGenerativeEnumConstructor, 37, 7),
      ],
    );
  }

  test_generative_unnamed_constructorReference() async {
    await assertErrorsInCode(
      '''
enum E {
  v
}

void f() {
  E.new;
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 29, 5)],
    );
  }

  test_generative_unnamed_instanceCreation_explicitConst() async {
    await assertErrorsInCode(
      '''
enum E {
  v
}

void f() {
  const E();
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 35, 1)],
    );
  }

  test_generative_unnamed_instanceCreation_explicitNew() async {
    await assertErrorsInCode(
      '''
enum E {
  v
}

void f() {
  new E();
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 33, 1)],
    );
  }

  test_generative_unnamed_instanceCreation_implicitNew() async {
    await assertErrorsInCode(
      '''
enum E {
  v
}

void f() {
  E();
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 29, 1)],
    );
  }

  test_generative_unnamed_redirectingConstructorInvocation() async {
    await assertNoErrorsInCode('''
enum E {
  v1,
  v2.named();

  const E();
  const E.named() : this();
}
''');
  }

  test_generative_unnamed_redirectingFactory() async {
    await assertErrorsInCode(
      '''
enum E {
  v;

  const factory E.named() = E;
  const E();
}
''',
      [error(diag.invalidReferenceToGenerativeEnumConstructor, 43, 1)],
    );
  }
}
