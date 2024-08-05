// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysSpecifyTypesTest);
  });
}

@reflectiveTest
class AlwaysSpecifyTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'always_specify_types';

  test_0() async {
    await assertNoDiagnostics(r'''
/// https://github.com/dart-lang/linter/issues/3275
typedef Foo1 = Map<String, Object>;
final Foo1 foo = Foo1();
''');
  }

  test_34() async {
    // https://github.com/dart-lang/linter/issues/851
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() {
  g<dynamic>();
  g();
}

@optionalTypeArgs
void g<T>() {}
''');
  }

  test_catchVariable_omitted() async {
    // https://codereview.chromium.org/1427223002/
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
    print(e);
  }
}
''');
  }

  test_constructorTearoff_keptGeneric() async {
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
}
''');
  }

  test_constructorTearoff_typeArgument() async {
    await assertDiagnostics(r'''
void f() {
  List<List>.filled;
}
''', [
      lint(18, 4),
    ]);
  }

  test_declaredVariable_genericTypeAlias() async {
    await assertDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
StringMap? x;
''', [
      lint(39, 10),
    ]);
  }

  test_declaredVariable_genericTypeAlias_inferredTypeArguments() async {
    await assertDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
StringMap x = StringMap<String>();
''', [
      lint(39, 9),
    ]);
  }

  test_extensionType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@optionalTypeArgs
extension type E<T>(int i) { }

void f() {
  E e = E(1);
}
''');
  }

  test_extensionType_typeArgs() async {
    await assertDiagnostics(r'''
extension type E<T>(int i) { }

void f() {
  E e = E(1);
}
''', [
      lint(45, 1),
      lint(51, 1),
    ]);
  }

  test_field_var() async {
    await assertDiagnostics(r'''
class C {
  var x;
}
''', [
      lint(12, 3),
    ]);
  }

  test_forLoopVariableDeclaration_var() async {
    await assertDiagnostics(r'''
void f() {
  for (var i = 0; i < 10; ++i) {
    print(i);
  }
}
''', [
      lint(18, 3),
    ]);
  }

  test_function_parameterType_explicit() async {
    await assertNoDiagnostics(r'''
void f(int x) {}
''');
  }

  test_function_parameterType_final() async {
    await assertDiagnostics(r'''
void f(final x) {}
''', [
      lint(7, 5),
    ]);
  }

  test_function_parameterType_omitted() async {
    await assertDiagnostics(r'''
void f(p) {}
''', [
      lint(7, 1),
    ]);
  }

  test_function_parameterType_var() async {
    await assertDiagnostics(r'''
void f(var p) {}
''', [
      lint(7, 3),
    ]);
  }

  test_functionExpression_parameterType_omitted() async {
    await assertDiagnostics(r'''
void f(List<String> p) {
  p.forEach((s) => print(s));
}
''', [
      lint(38, 1),
    ]);
  }

  test_functionExpression_parameterType_omitted_wildcard() async {
    await assertNoDiagnostics(r'''
void f(List<String> p) {
  p.forEach((_) {});
}
''');
  }

  test_functionExpression_parameterType_var() async {
    await assertDiagnostics(r'''
void f(List<String> p) {
  p.forEach((s) => print(s));
}
''', [
      lint(38, 1),
    ]);
  }

  test_genericFunctionTypedVariable_invocation_instantiated() async {
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
  filledList<int>(3, 3);
}
''');
  }

  test_genericFunctionTypedVariable_invocation_uninstantiated() async {
    // See #2914.
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
  filledList(3, 3);
}
''');
  }

  test_instanceCreation_genericTypeAlias_implicitTypeArgument() async {
    await assertDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
StringMap<String> x = StringMap();
''', [
      lint(61, 9),
    ]);
  }

  test_isExpression_typeArgument_implicit() async {
    await assertNoDiagnostics(r'''
void f(Object p) {
  p is Map;
}
''');
  }

  test_listLiteral_inferredTypeArgument() async {
    await assertDiagnostics(r'''
List<String> x = [];
''', [
      lint(17, 1),
    ]);
  }

  test_listPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var [a] = <int>[1];
}
''', [
      lint(13, 1),
    ]);
  }

  test_listPattern_destructured_listLiteral() async {
    await assertDiagnostics(r'''
f() {
  var [int a] = [1];
}
''', [
      lint(22, 1),
    ]);
  }

  test_listPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_localVariableDeclaration_var() async {
    await assertDiagnostics(r'''
void f() {
  var x = '';
}
''', [
      lint(13, 3),
    ]);
  }

  test_localVariableDeclaration_var_multiple() async {
    await assertDiagnostics(r'''
void f() {
  var x = '', y = 1.2;
}
''', [
      lint(13, 3),
    ]);
  }

  test_mapLiteral_inferredTypeArguments() async {
    await assertDiagnostics(r'''
Map<String, String> x = {};
''', [
      lint(24, 1),
    ]);
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var {'a': a} = <String, int>{'a': 1};
}
''', [
      lint(18, 1),
    ]);
  }

  test_mapPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_objectPattern_switch_final() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b):
  }
}
''', [
      lint(79, 5),
    ]);
  }

  test_objectPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && int b):
  }
}
''');
  }

  test_objectPattern_switch_var() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b):
  }
}
''', [
      lint(79, 3),
    ]);
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, var b):
  }
}
''', [
      lint(36, 5),
      lint(45, 3),
    ]);
  }

  test_recordPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (int a, int b):
  }
}
''');
  }

  test_setLiteral_inferredTypeArgument() async {
    await assertDiagnostics(r'''
Set<String> set = {};
''', [
      lint(18, 1),
    ]);
  }

  test_staticField_var() async {
    await assertDiagnostics(r'''
class C {
  var x;
}
''', [
      lint(12, 3),
    ]);
  }

  test_topLevelVariableDeclaration_explicitType() async {
    await assertNoDiagnostics(r'''
final int x = 3;
''');
  }

  test_topLevelVariableDeclaration_implicitTypeArgument() async {
    await assertDiagnostics(r'''
List? x;
''', [
      lint(0, 5),
    ]);
  }

  test_topLevelVariableDeclaration_missingType_const() async {
    await assertDiagnostics(r'''
const x = 2;
''', [
      lint(0, 5),
    ]);
  }

  test_topLevelVariableDeclaration_missingType_final() async {
    await assertDiagnostics(r'''
final x = 1;
''', [
      lint(0, 5),
    ]);
  }

  test_topLevelVariableDeclaration_missingType_final_multiple() async {
    await assertDiagnostics(r'''
final x = 1, y = '', z = 1.2;
''', [
      lint(0, 5),
    ]);
  }

  test_topLevelVariableDeclaration_missingType_multiple() async {
    await assertDiagnostics(r'''
var x = '', y = '';
''', [
      lint(0, 3),
    ]);
  }

  test_topLevelVariableDeclaration_typeArgument_implicitTypeArgument() async {
    await assertDiagnostics(r'''
List<List>? x;
''', [
      lint(5, 4),
    ]);
  }

  test_topLevelVariableDeclaration_var() async {
    await assertDiagnostics(r'''
var x;
''', [
      lint(0, 3),
    ]);
  }

  test_typedef_aliased_typeArgument_withImplicitTypeArgument() async {
    await assertDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
typedef MapList = List<StringMap>;
''', [
      lint(62, 9),
    ]);
  }

  test_typedef_typeArgument_withExplicitTypeArgument() async {
    await assertNoDiagnostics(r'''
typedef JsonMap = Map<String, dynamic>;
''');
  }

  test_typedef_typeArgument_withExplicitTypeArgument_typeVariable() async {
    await assertNoDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
''');
  }

  test_typedef_withImplicitTypeArgument() async {
    await assertDiagnostics(r'''
typedef RawList = List;
''', [
      lint(18, 4),
    ]);
  }
}
