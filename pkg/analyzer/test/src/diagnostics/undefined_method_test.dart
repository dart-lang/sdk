// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedMethodTest extends PubPackageResolutionTest {
  test_constructor_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.m();
}
C c = C.m();
''');
  }

  test_extensionMethodHiddenByStaticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
  static set foo(int x) {}
}

extension E on C {
  int foo() => 1;
}

''');
  }

  test_extensionMethodShadowingTopLevelSetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
}

extension E on C {
  int foo() => 1;
}

set foo(int x) {}
''');
  }

  test_functionAlias_notInstantiated() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn.foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionExpression_callMethod_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (() => null).call();
}
''');
  }

  test_functionExpression_directCall_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (() => null)();
}
''');
  }

  test_ignore_libraryImport_show_it_implicitThis() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show foo;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class A {
  void f() {
    foo();
  }
}
''');
  }

  test_ignore_libraryImport_show_other_implicitThis() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show bar;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class A {
  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'A'.
  }
}
''');
  }

  test_localSetterShadowingExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E1 on C {
  int foo(int x) => 1;
}

extension E2 on C {
  static set foo(int x) {}

  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
}
''');
  }

  test_method_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    abs();
//  ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'C'.
  }
}
''');
  }

  test_static_conditionalAccess_defined() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void m() {}
}
f() { A?.m(); }
//     ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }
}
