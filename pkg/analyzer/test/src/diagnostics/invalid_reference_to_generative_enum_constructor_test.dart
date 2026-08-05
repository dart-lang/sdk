// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named;
//^^^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
}
''');
  }

  test_generative_named_instanceCreation_implicitNew() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named();
//^^^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
  }

  test_generative_named_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v;

  const E() : this.named();
  const E.named();
}
''');
  }

  test_generative_named_redirectingFactory() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v;
//^
// [diag.enumConstantInvokesFactoryConstructor] An enum value can't invoke a factory constructor.

  const factory E() = E.named;
//                    ^^^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  const E.named();
}
''');
  }

  test_generative_unnamed_constructorReference() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v
}

void f() {
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
}
''');
  }

  test_generative_unnamed_instanceCreation_explicitConst() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v
}

void f() {
  const E();
//      ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
  }

  test_generative_unnamed_instanceCreation_explicitNew() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v
}

void f() {
  new E();
//    ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
  }

  test_generative_unnamed_instanceCreation_implicitNew() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v
}

void f() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
  }

  test_generative_unnamed_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v1,
  v2.named();

  const E();
  const E.named() : this();
}
''');
  }

  test_generative_unnamed_redirectingFactory() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  v;

  const factory E.named() = E;
//                          ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  const E();
}
''');
  }
}
