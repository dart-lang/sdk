// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitCallTearoffsTest);
  });
}

@reflectiveTest
class ImplicitCallTearoffsTest extends LintRuleTest {
  @override
  String get lintRule => 'implicit_call_tearoffs';

  test_explicitCallTearoff() async {
    await assertNoDiagnostics(r'''
void Function() f() => C().call;
class C {
  void call() {}
}
''');
  }

  test_ifNullExpression_functionTypeContext() async {
    await assertDiagnostics(r'''
void Function() f(C? c1, C c2) {
  return c1 ?? c2;
}
class C {
  void call() {}
}
''', [
      lint(42, 8),
    ]);
  }

  test_instanceCreation_argumentToFunctionTypeParameter() async {
    await assertDiagnostics(r'''
void f() {
  g(C());
}
class C {
  void call() {}
}
void g(void Function() f) {}
''', [
      lint(15, 3),
    ]);
  }

  test_instanceCreation_argumentToFunctionTypeParameter_instantiatedTypeArgument() async {
    await assertDiagnostics(r'''
void f() {
  g(C());
}
void g(void Function(int) f) {}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(15, 3),
    ]);
  }

  test_instanceCreation_cascadeExpression_functionTypeContext() async {
    await assertDiagnostics(r'''
void Function() f() {
  return C()..other();
}
class C {
  void call() {}
  void other() {}
}
''', [
      lint(31, 12),
    ]);
  }

  test_instanceCreation_functionContext() async {
    await assertDiagnostics(r'''
Function f = C();
class C {
  void call<T>(T arg) {}
}
''', [
      lint(13, 3),
    ]);
  }

  test_instanceCreation_functionTypeContext() async {
    await assertDiagnostics(r'''
void Function() f = C();
class C {
  void call() {}
}
''', [
      lint(20, 3),
    ]);
  }

  test_instanceCreation_functionTypeContext_instantiatedTypeArgument() async {
    await assertDiagnostics(r'''
void Function(int) f = C();
class C {
  void call<T>(T arg) {}
}
''', [
      lint(23, 3),
    ]);
  }

  test_instanceCreation_genericFunctionTypeContext() async {
    await assertDiagnostics(r'''
void Function<T>(T) f = C();
class C {
  void call<T>(T arg) {}
}
''', [
      lint(24, 3),
    ]);
  }

  test_instanceCreation_noContext() async {
    await assertNoDiagnostics(r'''
final c = C();
class C {
  void call<T>(T arg) {}
}
''');
  }

  test_simpleIdentifier_argumentToFunctionTypedParameter() async {
    await assertDiagnostics(r'''
void f(C c) {
  g(c);
}
void g(void Function() f) {}
class C {
  void call() {}
}
''', [
      lint(18, 1),
    ]);
  }

  test_simpleIdentifier_argumentToFunctionTypeParameter_instantiatedTypeArgument() async {
    await assertDiagnostics(r'''
void f(C c) {
  g(c);
}
void g(void Function(int) f) {}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(18, 1),
    ]);
  }

  test_simpleIdentifier_functionContext() async {
    await assertDiagnostics(r'''
void f(C c) {
  Function fn = c;
}
class C {
  void call() {}
}
''', [
      lint(30, 1),
    ]);
  }

  test_simpleIdentifier_functionTypeContext() async {
    await assertDiagnostics(r'''
void Function() f(C c) => c;
class C {
  void call() {}
}
''', [
      lint(26, 1),
    ]);
  }

  test_simpleIdentifier_functionTypeContext_instantiatedTypeArgument() async {
    await assertDiagnostics(r'''
void Function(int) f(C c) => c;
class C {
  void call<T>(T arg) {}
}
''', [
      lint(29, 1),
    ]);
  }

  test_simpleIdentifier_functionTypeContext_listTypArgument() async {
    await assertDiagnostics(r'''
void f(C c) {
  <void Function()>[c];
}
class C {
  void call() {}
}
''', [
      lint(34, 1),
    ]);
  }

  test_simpleIdentifier_genericFunctionTypeContext() async {
    await assertDiagnostics(r'''
void f(C c) {
  void Function<T>(T) fn = c;
}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(41, 1),
    ]);
  }

  test_simpleIdentifier_listLiteral_listOfFunctionTypeContext() async {
    await assertDiagnostics(r'''
List<void Function()> f(C c) {
  return [c];
}
class C {
  void call() {}
}
''', [
      lint(41, 1),
    ]);
  }

  test_tearoffInstantiation_argumentToFunctionTypeParameter() async {
    await assertDiagnostics(r'''
void f(C c) {
  g(c<int>);
}
void g(void Function(int) f) {}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(18, 6),
    ]);
  }

  test_tearoffInstantiation_functionContext() async {
    await assertDiagnostics(r'''
void f(C c) {
  Function fn = c<int>;
}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(30, 6),
    ]);
  }

  test_tearoffInstantiation_functionTypeContext() async {
    await assertDiagnostics(r'''
void f(C c) {
  void Function(int) fn = c<int>;
}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(40, 6),
    ]);
  }

  test_tearoffInstantiation_noContext() async {
    await assertDiagnostics(r'''
void f(C c) {
  c<int>;
}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(16, 6),
    ]);
  }

  test_tearoffInstantiationOfInstanceCreation_argumentToFunctionTypeParameter() async {
    await assertDiagnostics(r'''
void f() {
  g(C()<int>);
}
void g(void Function(int) f) {}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(15, 8),
    ]);
  }

  test_tearoffInstantiationOfInstanceCreation_functionContext() async {
    await assertDiagnostics(r'''
Function f = C()<int>; // LINT
class C {
  void call<T>(T arg) {}
}
''', [
      lint(13, 8),
    ]);
  }

  test_tearoffInstantiationOfInstanceCreation_functionTypeContext() async {
    await assertDiagnostics(r'''
void Function(int) f = C()<int>;
class C {
  void call<T>(T arg) {}
}
''', [
      lint(23, 8),
    ]);
  }

  test_tearoffInstantiationofInstanceCreation_noContext() async {
    await assertDiagnostics(r'''
void f() {
  C()<int>;
}
class C {
  void call<T>(T arg) {}
}
''', [
      lint(13, 8),
    ]);
  }
}
