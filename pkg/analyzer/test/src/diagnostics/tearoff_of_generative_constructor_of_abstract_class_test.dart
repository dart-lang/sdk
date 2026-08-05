// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearoffOfGenerativeConstructorOfAbstractClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TearoffOfGenerativeConstructorOfAbstractClassTest
    extends PubPackageResolutionTest {
  test_abstractClass_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  factory A() => B();
}

class B implements A {}

void foo() {
  A.new;
}
''');
  }

  test_abstractClass_factoryConstructor_viaEquals() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  factory A() = B;
}

class B implements A {}

void foo() {
  A.new;
}
''');
  }

  test_abstractClass_generativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  A();
}

void foo() {
  A.new;
//^^^^^
// [diag.tearoffOfGenerativeConstructorOfAbstractClass] A generative constructor of an abstract class can't be torn off.
}
''');
  }

  test_concreteClass_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => A.two();

  A.two();
}

void foo() {
  A.new;
}
''');
  }

  test_concreteClass_factoryConstructor_viaEquals() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() = A.two;

  A.two();
}

void foo() {
  A.new;
}
''');
  }

  test_concreteClass_generativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}

void foo() {
  A.new;
}
''');
  }
}
