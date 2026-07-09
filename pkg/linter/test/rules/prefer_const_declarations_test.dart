// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstDeclarationsTest);
  });
}

@reflectiveTest
class PreferConstDeclarationsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_const_declarations;

  test_constructorTearoff_inference() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final C<int> Function() c = C.new!];
}
class C<T> {}
''');
  }

  test_constructorTearoff_instantiatedWithType() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final c = C<int>.new!];
}
class C<T> {}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/2911')
  test_constructorTearoff_instantiatedWithTypeVariable() async {
    await assertNoDiagnostics(r'''
void f<T>() {
  final c = C<T>.new;
}
class C<T> {}
''');
  }

  test_constructorTearoff_uninstantiated() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = C.new!];
}
class C<T> {}
''');
  }

  test_instanceField_final_listLiteral_const() async {
    await assertNoDiagnostics(r'''
class C {
  final x = const [];
}
''');
  }

  test_localVariable_const_listLiteral_const() async {
    await assertNoDiagnostics(r'''
void f() {
  const x = const [];
}
''');
  }

  test_localVariable_final_constructorInvocation_const() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = const C()!];
}
class C {
  const C();
}
''');
  }

  test_localVariable_final_constructorInvocation_new() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = C();
}
class C {
  const C();
}
''');
  }

  test_localVariable_final_doubleLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = 1.3!];
}
''');
  }

  test_localVariable_final_intLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = 1!];
}
''');
  }

  test_localVariable_final_intLiteral_multiple() async {
    // https://github.com/dart-lang/sdk/issues/32745
    await assertNoDiagnostics(r'''
void f() {
  final x, y = 1;
}
''');
  }

  test_localVariable_final_listLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = [];
}
''');
  }

  test_localVariable_final_listLiteral_const() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = const []!];
}
''');
  }

  test_localVariable_final_mapOrSetLiteral_const() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = const {}!];
}
''');
  }

  test_localVariable_final_methodInvocation() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = 7.toString();
}
''');
  }

  test_localVariable_final_nullLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = null!];
}
''');
  }

  test_localVariable_final_prefixedIdentifier() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = 7.hashCode;
}
''');
  }

  test_localVariable_final_staticProperty_const() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = C.p!];
}
class C {
  const C();
  static const p = const [];
}
''');
  }

  test_localVariable_final_stringLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = ''!];
}
''');
  }

  test_localVariable_listLiteral_final_typed() async {
    await assertNoDiagnostics(r'''
void f() {
  final List<int> x = [];
}
''');
  }

  test_localVariable_listLiteral_final_typed_typeArg() async {
    await assertNoDiagnostics(r'''
void f() {
  final List<int> x = <int>[];
}
''');
  }

  test_localVariable_listLiteral_final_untyped_typeArg() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = <int>[];
}
''');
  }

  test_localVariable_mapLiteral_final_typed() async {
    await assertNoDiagnostics(r'''
void f() {
  final Map<int,int> x = {};
}
''');
  }

  test_localVariable_mapLiteral_final_typed_typeArgs() async {
    await assertNoDiagnostics(r'''
void f() {
  final Map<int,int> x = <int,int>{};
}
''');
  }

  test_localVariable_mapLiteral_final_untyped_typeArgs() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = <int,int>{};
}
''');
  }

  test_localVariable_mapOrSetLiteral_final_untyped() async {
    await assertNoDiagnostics(r'''
void f() {
  final x = {};
}
''');
  }

  test_localVariable_setLiteral_final_typed() async {
    await assertNoDiagnostics(r'''
void f() {
  final Set<int> x = {};
}
''');
  }

  test_localVariable_setLiteral_final_typed_typeArg() async {
    await assertNoDiagnostics(r'''
void f() {
  final Set<int> ids2 = <int>{};
}
''');
  }

  test_recordLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
[!final tuple = const ("first", 2, true)!];
''');
  }

  test_staticField_const_listLiteral_const() async {
    await assertNoDiagnostics(r'''
class C {
  static const x = const [];
}
''');
  }

  test_staticField_final_listLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!final x = const []!];
}
''');
  }

  test_staticField_final_listLiteral_const() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!final x = const []!];
}
''');
  }

  test_staticField_final_nullLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!final x = null!];
}
''');
  }

  test_staticFunctionTearoff_inference() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final C<int> Function() c = C.m!];
}
class C<T> {
  static C<X> m<X>() => C<X>();
}
''');
  }

  test_staticFunctionTearoff_instantiatedWithType() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final c = C.m<int>!];
}
class C<T> {
  static C<X> m<X>() => C<X>();
}
''');
  }

  test_staticFunctionTearoff_instantiatedWithTypeVariable() async {
    await assertNoDiagnostics(r'''
void f<T>() {
  final c = C.m<T>;
}
class C<T> {
  static C<X> m<X>() => C<X>();
}
''');
  }

  test_staticFunctionTearoff_uninstantiated() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final x = C.m!];
}
class C<T> {
  static C<X> m<X>() => C<X>();
}
''');
  }

  test_test_recordLiteral_nonConst() async {
    await assertNoDiagnostics(r'''
final tuple = (1, () {});
''');
  }

  test_test_recordLiteral_ok() async {
    await assertNoDiagnostics(r'''
const record = (number: 123, name: "Main", type: "Street");
''');
  }

  test_topLevelVariable_final_doubleLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
[!final x = 1.3!];
''');
  }

  test_topLevelVariable_final_listLiteral() async {
    await assertNoDiagnostics(r'''
final x = [];
''');
  }

  test_topLevelVariable_final_listLiteral_const() async {
    await assertDiagnosticsFromMarkup(r'''
[!final x = const []!];
''');
  }

  test_topLevelVariable_final_mapOrSetLiteral() async {
    await assertNoDiagnostics(r'''
final o9 = {};
''');
  }

  test_topLevelVariable_final_mapOrSetLiteral_const() async {
    await assertDiagnosticsFromMarkup(r'''
[!final x = const {}!];
''');
  }

  test_topLevelVariable_final_nullLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
[!final a = null!];
''');
  }

  test_topLevelVariable_final_topLevelVariable_const() async {
    await assertDiagnosticsFromMarkup(r'''
const x = const [];
[!final y = x!];
''');
  }

  test_topLevelVariable_listLiteral_const() async {
    await assertNoDiagnostics(r'''
const x = const [];
''');
  }
}
