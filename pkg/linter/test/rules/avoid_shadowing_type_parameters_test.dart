// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidShadowingTypeParametersTest);
  });
}

@reflectiveTest
class AvoidShadowingTypeParametersTest extends LintRuleTest {
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
    await assertDiagnosticsFromMarkup(r'''
typedef Fn1<T> = void Function<[!T!]>(T);
''');
  }

  test_functionTypedParameter_shadowingFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void fn2<T>(void Function<[!T!]>()) {}
''');
  }

  test_genericFunctionType_shadowingFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f<T>() {
  void Function<[!T!]>(T) g;
}
''');
  }

  test_localFunction_noShadowing() async {
    await assertNoDiagnostics(r'''
void f<T>() {
  void g<U>() {}
}
''');
  }

  test_localFunction_shadowingClass() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {
  void f() {
    void g<[!T!]>() {}
  }
}
''');
  }

  test_localFunction_shadowingFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f<T>() {
  void g<[!T!]>() {}
}
''');
  }

  test_localFunction_shadowingLocalFunction() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f() {
    void g<T>() {
      void h<[!T!]>() {}
    }
  }
}
''');
  }

  test_localFunction_shadowingMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {
  void fn1<U>() {
    void fn3<[!U!]>() {}
  }
}
''');
  }

  test_method_noShadowing() async {
    await assertNoDiagnostics(r'''
class C<T> {
  void f<U>() {}
}
''');
  }

  test_method_shadowingClass() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {
  void f<[!T!]>() {}
}
''');
  }

  test_method_shadowingEnum() async {
    await assertDiagnosticsFromMarkup(r'''
enum E<T> {
  a, b, c;
  void fn<[!T!]>() {}
}
''');
  }

  test_method_shadowingExtension() async {
    await assertDiagnosticsFromMarkup(r'''
extension E<T> on List<T> {
  void f<[!T!]>() {}
}
''');
  }

  test_method_shadowingExtensionType() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(int i) {
  void m<[!T!]>() {}
}
''');
  }

  test_method_shadowingMixin() async {
    await assertDiagnosticsFromMarkup(r'''
mixin M<T> {
  void f<[!T!]>() {}
}
''');
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
    await assertDiagnostics(
      r'''
typedef Predicate = bool <E>(E element);
''',
      [
        // No lint.
        error(diag.wrongNumberOfTypeArguments, 20, 8),
        error(diag.nonTypeAsTypeArgument, 26, 1),
        error(diag.expectedToken, 28, 1),
        error(diag.undefinedClass, 29, 1),
      ],
    );
  }
}
