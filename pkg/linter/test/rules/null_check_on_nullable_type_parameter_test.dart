// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckOnNullableTypeParameterTest);
  });
}

@reflectiveTest
class NullCheckOnNullableTypeParameterTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.null_check_on_nullable_type_parameter;

  test_expectedDynamic() async {
    await assertNoDiagnostics(r'''
dynamic f<T>(T? p) => p!;
''');
  }

  test_expectedSameTypeVariable_arrow() async {
    await assertDiagnosticsFromMarkup(r'''
T f<T>(T? p) => p[!!!];
''');
  }

  test_expectedSameTypeVariable_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f<T>(T? p) {
  T t;
  t = p[!!!];
}
''');
  }

  test_expectedSameTypeVariable_assignmentInDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
void f<T>(T? p) { T t = p[!!!]; }
''');
  }

  test_expectedSameTypeVariable_block() async {
    await assertDiagnosticsFromMarkup(r'''
T f<T>(T? p) { return p[!!!]; }
''');
  }

  test_inAsExpression() async {
    await assertNoDiagnostics(r'''
R f<P, R>(P? p) => p! as R;
''');
  }

  test_inAssignmentToNonNullableField() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {
  late T t;
  void f(T? p) {
    t = p[!!!];
  }
}
''');
  }

  test_inListLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
List<T> f<T>(T? p) => [p[!!/**/!]];
''');
  }

  test_inMapLiteralKey() async {
    await assertDiagnosticsFromMarkup(r'''
Map<T, String> f<T>(T? p) => {p[!!!]: ''};
''');
  }

  test_inMapLiteralValue() async {
    await assertDiagnosticsFromMarkup(r'''
Map<String, T> f<T>(T? p) => {'': p[!!!]};
''');
  }

  test_inSetLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
Set<T> f<T>(T? p) => {p[!!!]};
''');
  }

  test_inTargetOfObjectGetterCall() async {
    await assertNoDiagnostics(r'''
int f<T>(T? p) => p!.hashCode;
''');
  }

  test_inTargetOfObjectMethodCall() async {
    await assertNoDiagnostics(r'''
String f<T>(T? p) => p!.toString();
''');
  }

  test_inTargetOfObjectMethodCall_cascade() async {
    await assertNoDiagnostics(r'''
T f<T>(T? p) => p!..toString();
''');
  }

  test_inYieldAsync() async {
    await assertDiagnosticsFromMarkup(r'''
Stream<T> f<T>(T? p) async* {yield p[!!!];}
''');
  }

  test_inYieldSync() async {
    await assertDiagnosticsFromMarkup(r'''
Iterable<T> f<T>(T? p) sync* {yield p[!!!];}
''');
  }

  test_nullAssertPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f<T>(T? x){
  if (x case var y[!!!]) print(y);
}
''');
  }

  test_nullAssertPattern_list() async {
    await assertDiagnosticsFromMarkup(r'''
f<T>(List<T?> l){
  var [x[!!!], y] = l;
}
''');
  }

  test_nullAssertPattern_logicalOr() async {
    await assertDiagnostics(
      r'''
f<T>(T? x){
  switch(x) {
    case var y! || var y! : print(y);
  }
}
''',
      [lint(40, 1), error(diag.deadCode, 42, 9), lint(50, 1)],
    );
  }

  test_nullAssertPattern_map() async {
    await assertDiagnosticsFromMarkup(r'''
f<T>(Map<String, T?> m){
  var {'x': y[!!!]} = m;
}
''');
  }

  test_nullAssertPattern_object() async {
    await assertDiagnosticsFromMarkup(r'''
class A<E> {
  E? a;
  A(this.a);
}

f<T>(T? t, A<T> u) {
  A(a: t[!!!]) = u;
}
''');
  }

  test_nullAssertPattern_record() async {
    await assertDiagnosticsFromMarkup(r'''
f<T>((T?, T?) p){
  var (x[!!!], y) = p;
}
''');
  }

  test_potentiallyNonNullableTypeVariable() async {
    await assertNoDiagnostics(r'''
T f<T>(T p) => p!; // OK
''');
  }

  test_typeParameterBoundToDynamic() async {
    await assertDiagnosticsFromMarkup(r'''
T f<T extends dynamic>(T? p) => p[!!!];
''');
  }

  test_typeParameterBoundToNullableObject() async {
    await assertDiagnosticsFromMarkup(r'''
T f<T extends Object?>(T? p) => p[!!!];
''');
  }

  test_typeParameterBoundToObject() async {
    await assertNoDiagnostics(r'''
T f<T extends Object>(T? p) => p!;
''');
  }

  test_typeParameterExtendsNullableObject_inAwaited() async {
    await assertDiagnosticsFromMarkup(r'''
Future<T> f<T extends Object?>(T? p) async => await p[!!!];
''');
  }

  test_typeParameterExtendsNullableObject_inAwaitedInList() async {
    await assertDiagnosticsFromMarkup(r'''
Future<List<T>> f<T extends Object?>(T? p) async => await [p[!!/**/!]];
''');
  }
}
