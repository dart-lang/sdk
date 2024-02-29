// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingRequiredParamTest);
  });
}

@reflectiveTest
class MissingRequiredParamTest extends PubPackageResolutionTest {
  test_annotation_noImportPrefix_named() async {
    await assertErrorsInCode(r'''
class A {
  const A.named({required int a});
}

@A.named()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 51, 5),
    ]);
  }

  test_annotation_noImportPrefix_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  const A({required int a});
}

@A()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 43, 1),
    ]);
  }

  test_annotation_withImportPrefix_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named({required int a});
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as a;

@a.A.named()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 28, 5),
    ]);
  }

  test_annotation_withImportPrefix_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({required int a});
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as a;

@a.A()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 26, 1),
    ]);
  }

  test_constructor_argumentGiven() async {
    await assertNoErrorsInCode(r'''
class C {
  C({required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_missingArgument() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}
main() {
  new C();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 52, 1),
    ]);
  }

  test_constructor_redirectingConstructorCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int x});
  C.named() : this();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 47, 6),
    ]);
  }

  test_constructor_superCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}

class D extends C {
  D() : super();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 66, 7),
    ]);
  }

  test_constructor_superFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super();
}
''');
  }

  test_enumConstant_withArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  const E({required int a});
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 11, 1),
    ]);
  }

  test_enumConstant_withoutArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E({required int a});
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 11, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
void f({required int a}) {}

main() {
  f();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 40, 1),
    ]);
  }

  test_function_call() async {
    await assertErrorsInCode(r'''
void f({required int a}) {}

main() {
  f.call();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 46, 2),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode(r'''
void Function({required int a}) f() => throw '';
g() {
  f()();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 57, 5),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  void m({required int a}) {}
}
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 58, 1),
    ]);
  }

  test_method_inOtherLib() async {
    newFile('$testPackageLibPath/a_lib.dart', r'''
class A {
  void m({required int a}) {}
}
''');
    await assertErrorsInCode(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 37, 1),
    ]);
  }

  test_typedef_function() async {
    await assertErrorsInCode(r'''
String test(C c) => c.m()();

typedef String F({required String x});

class C {
  F m() => ({required String x}) => throw '';
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 20, 7),
    ]);
  }
}
