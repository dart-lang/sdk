// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerOutsideConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerOutsideConstructorTest extends PubPackageResolutionTest {
  test_closure() async {
    await assertErrorsInCode(
      r'''
class A {
  dynamic field = ({this.field}) {};
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 30, 10)],
    );
  }

  test_defaultParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  int x = 0;
  m([this.x = 0]) {}
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 28, 6)],
    );
  }

  test_functionTypedFieldFormalParameter() async {
    // TODO(srawlins): Fix the duplicate error messages.
    await assertErrorsInCode(
      r'''
class A {
  int Function()? x;
  m(int this.x()) {}
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 35, 12)],
    );
  }

  test_inFunctionTypedParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  int? x;
  A(int p(this.x));
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 30, 6)],
    );
  }

  test_localFunction_optionalNamed() async {
    await assertErrorsInCode(
      r'''
void f() {
  void foo({this.x}) {}
  foo(x: 0);
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 23, 6)],
    );
  }

  test_localFunction_optionalPositional() async {
    await assertErrorsInCode(
      r'''
void f() {
  void foo([this.x]) {}
  foo(0);
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 23, 6)],
    );
  }

  test_localFunction_requiredNamed() async {
    await assertErrorsInCode(
      r'''
void f() {
  void foo({required this.x}) {}
  foo(x: 0);
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 23, 15)],
    );
  }

  test_localFunction_requiredPositional() async {
    await assertErrorsInCode(
      r'''
void f() {
  void foo(this.x) {}
  foo(0);
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 22, 6)],
    );
  }

  test_method() async {
    // TODO(brianwilkerson): Fix the duplicate error messages.
    await assertErrorsInCode(
      r'''
class A {
  int? x;
  m(this.x) {}
}
''',
      [error(diag.fieldInitializerOutsideConstructor, 24, 6)],
    );
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
f(this.x(y)) {}
''',
      [error(diag.fieldInitializerOutsideConstructor, 2, 9)],
    );
  }
}
