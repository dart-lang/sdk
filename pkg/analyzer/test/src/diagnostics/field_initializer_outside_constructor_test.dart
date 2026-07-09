// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic field = ({this.field}) {};
//                  ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
}
''');
  }

  test_defaultParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  m([this.x = 0]) {}
//   ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
}
''');
  }

  test_functionTypedFieldFormalParameter() async {
    // TODO(srawlins): Fix the duplicate error messages.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int Function()? x;
  m(int this.x()) {}
//      ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
}
''');
  }

  test_inFunctionTypedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? x;
  A(int p(this.x));
//        ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
}
''');
  }

  test_localFunction_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo({this.x}) {}
//          ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
  foo(x: 0);
}
''');
  }

  test_localFunction_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo([this.x]) {}
//          ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
  foo(0);
}
''');
  }

  test_localFunction_requiredNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo({required this.x}) {}
//                   ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
  foo(x: 0);
}
''');
  }

  test_localFunction_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void foo(this.x) {}
//         ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
  foo(0);
}
''');
  }

  test_method() async {
    // TODO(brianwilkerson): Fix the duplicate error messages.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? x;
  m(this.x) {}
//  ^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
}
''');
  }

  test_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f(this.x(y)) {}
//^^^^
// [diag.fieldInitializerOutsideConstructor] Field formal parameters can only be used in a constructor.
''');
  }
}
