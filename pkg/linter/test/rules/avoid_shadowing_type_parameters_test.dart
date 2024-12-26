// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidShadowingTypeParametersTest);
  });
}

@reflectiveTest
class AvoidShadowingTypeParametersTest extends LintRuleTest {
  @override
  List<ErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => LintNames.avoid_shadowing_type_parameters;

  test_enclosingElementsWithoutTypeParameters() async {
    // Make sure we don't hit any null pointers when none of a function or
    // method's ancestors have type parameters.
    await assertNoDiagnostics(r'''
class C {
  void f() {
    void g() {
      void h<T>() {}
    }
  }
  void i<T>() {}
}
''');
  }

  test_functionType_enclosingElementWithoutTypeParameters() async {
    await assertNoDiagnostics(r'''
typedef Fn5 = void Function<T>(T);
''');
  }

  test_functionType_noShadowing() async {
    await assertNoDiagnostics(r'''
typedef Fn2<T> = void Function<U>(T);
''');
  }

  test_functionType_shadowingTypedef() async {
    await assertDiagnostics(r'''
typedef Fn1<T> = void Function<T>(T);
''', [
      lint(31, 1),
    ]);
  }

  @FailingTest(reason: '')
  test_functionTypedParameter_shadowingFunction() async {
    // TODO(srawlins): Report lint here.
    await assertDiagnostics(r'''
void fn2<T>(void Function<T>()) {}
''', [
      lint(26, 1),
    ]);
  }

  test_localFunction_noShadowing() async {
    await assertNoDiagnostics(r'''
void f<T>() {
  void g<U>() {}
}
''');
  }

  test_localFunction_shadowingClass() async {
    await assertDiagnostics(r'''
class C<T> {
  void f() {
    void g<T>() {}
  }
}
''', [
      lint(37, 1),
    ]);
  }

  test_localFunction_shadowingFunction() async {
    await assertDiagnostics(r'''
void f<T>() {
  void g<T>() {}
}
''', [
      lint(23, 1),
    ]);
  }

  test_localFunction_shadowingLocalFunction() async {
    await assertDiagnostics(r'''
class C {
  void f() {
    void g<T>() {
      void h<T>() {}
    }
  }
}
''', [
      lint(54, 1),
    ]);
  }

  test_localFunction_shadowingMethod() async {
    await assertDiagnostics(r'''
class C<T> {
  void fn1<U>() {
    void fn3<U>() {}
  }
}
''', [
      lint(44, 1),
    ]);
  }

  test_method_noShadowing() async {
    await assertNoDiagnostics(r'''
class C<T> {
  void f<U>() {}
}
''');
  }

  test_method_shadowingClass() async {
    await assertDiagnostics(r'''
class C<T> {
  void f<T>() {}
}
''', [
      lint(22, 1),
    ]);
  }

  test_method_shadowingEnum() async {
    await assertDiagnostics(r'''
enum E<T> {
  a, b, c;
  void fn<T>() {}
}
''', [
      lint(33, 1),
    ]);
  }

  test_method_shadowingExtension() async {
    await assertDiagnostics(r'''
extension E<T> on List<T> {
  void f<T>() {}
}
''', [
      lint(37, 1),
    ]);
  }

  test_method_shadowingExtensionType() async {
    await assertDiagnostics(r'''
extension type E<T>(int i) {
  void m<T>() {}
}
''', [
      lint(38, 1),
    ]);
  }

  test_method_shadowingMixin() async {
    await assertDiagnostics(r'''
mixin M<T> {
  void f<T>() {}
}
''', [
      lint(22, 1),
    ]);
  }

  test_staticMethod_shadowingClass() async {
    await assertNoDiagnostics(r'''
class A<T> {
  static void f<T>() {}
}
''');
  }

  test_wildcards() async {
    await assertNoDiagnostics(r'''
class A<_> {
  void f<_>() {}
}
''');
  }

  test_wrongNumberOfTypeArguments() async {
    await assertDiagnostics(r'''
typedef Predicate = bool <E>(E element);
''', [
      // No lint.
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 20, 8),
      error(CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT, 26, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 28, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 29, 1),
    ]);
  }
}
