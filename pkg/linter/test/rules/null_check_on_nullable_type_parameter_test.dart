// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckOnNullableTypeParameterTest);
  });
}

@reflectiveTest
class NullCheckOnNullableTypeParameterTest extends LintRuleTest {
  @override
  String get lintRule => 'null_check_on_nullable_type_parameter';

  test_expectedDynamic() async {
    await assertNoDiagnostics(r'''
dynamic f<T>(T? p) => p!;
''');
  }

  test_expectedSameTypeVariable_arrow() async {
    await assertDiagnostics(r'''
T f<T>(T? p) => p!;
''', [
      lint(17, 1),
    ]);
  }

  test_expectedSameTypeVariable_assignment() async {
    await assertDiagnostics(r'''
void f<T>(T? p) {
  T t;
  t = p!;
}
''', [
      lint(32, 1),
    ]);
  }

  test_expectedSameTypeVariable_assignmentInDeclaration() async {
    await assertDiagnostics(r'''
void f<T>(T? p) { T t = p!; }
''', [
      lint(25, 1),
    ]);
  }

  test_expectedSameTypeVariable_block() async {
    await assertDiagnostics(r'''
T f<T>(T? p) { return p!; }
''', [
      lint(23, 1),
    ]);
  }

  test_inAsExpression() async {
    await assertNoDiagnostics(r'''
R f<P, R>(P? p) => p! as R;
''');
  }

  test_inAssignmentToNonNullableField() async {
    await assertDiagnostics(r'''
class C<T> {
  late T t;
  void f(T? p) {
    t = p!;
  }
}
''', [
      lint(51, 1),
    ]);
  }

  test_inListLiteral() async {
    await assertDiagnostics(r'''
List<T> f<T>(T? p) => [p!];
''', [
      lint(24, 1),
    ]);
  }

  test_inMapLiteralKey() async {
    await assertDiagnostics(r'''
Map<T, String> f<T>(T? p) => {p!: ''};
''', [
      lint(31, 1),
    ]);
  }

  test_inMapLiteralValue() async {
    await assertDiagnostics(r'''
Map<String, T> f<T>(T? p) => {'': p!};
''', [
      lint(35, 1),
    ]);
  }

  test_inSetLiteral() async {
    await assertDiagnostics(r'''
Set<T> f<T>(T? p) => {p!};
''', [
      lint(23, 1),
    ]);
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
    await assertDiagnostics(r'''
Stream<T> f<T>(T? p) async* {yield p!;}
''', [
      lint(36, 1),
    ]);
  }

  test_inYieldSync() async {
    await assertDiagnostics(r'''
Iterable<T> f<T>(T? p) sync* {yield p!;}
''', [
      lint(37, 1),
    ]);
  }

  test_nullAssertPattern_ifCase() async {
    await assertDiagnostics(r'''
f<T>(T? x){
  if (x case var y!) print(y);
}
''', [
      lint(30, 1),
    ]);
  }

  test_nullAssertPattern_list() async {
    await assertDiagnostics(r'''
f<T>(List<T?> l){
  var [x!, y] = l;
}
''', [
      lint(26, 1),
    ]);
  }

  test_nullAssertPattern_logicalOr() async {
    await assertDiagnostics(r'''
f<T>(T? x){
  switch(x) {
    case var y! || var y! : print(y);
  }
}
''', [
      lint(40, 1),
      error(WarningCode.DEAD_CODE, 42, 9),
      lint(50, 1),
    ]);
  }

  test_nullAssertPattern_map() async {
    await assertDiagnostics(r'''
f<T>(Map<String, T?> m){
  var {'x': y!} = m;
}
''', [
      lint(38, 1),
    ]);
  }

  test_nullAssertPattern_object() async {
    await assertDiagnostics(r'''
class A<E> {
  E? a;
  A(this.a);
}

f<T>(T? t, A<T> u) {
  A(a: t!) = u;
}
''', [
      lint(66, 1),
    ]);
  }

  test_nullAssertPattern_record() async {
    await assertDiagnostics(r'''
f<T>((T?, T?) p){
  var (x!, y) = p;
}
''', [
      lint(26, 1),
    ]);
  }

  test_potentiallyNonNullableTypeVariable() async {
    await assertNoDiagnostics(r'''
T f<T>(T p) => p!; // OK
''');
  }

  test_typeParameterBoundToDynamic() async {
    await assertDiagnostics(r'''
T f<T extends dynamic>(T? p) => p!;
''', [
      lint(33, 1),
    ]);
  }

  test_typeParameterBoundToNullableObject() async {
    await assertDiagnostics(r'''
T f<T extends Object?>(T? p) => p!;
''', [
      lint(33, 1),
    ]);
  }

  test_typeParameterBoundToObject() async {
    await assertNoDiagnostics(r'''
T f<T extends Object>(T? p) => p!;
''');
  }

  test_typeParameterExtendsNullableObject_inAwaited() async {
    await assertDiagnostics(r'''
Future<T> f<T extends Object?>(T? p) async => await p!;
''', [
      lint(53, 1),
    ]);
  }

  test_typeParameterExtendsNullableObject_inAwaitedInList() async {
    await assertDiagnostics(r'''
Future<List<T>> f<T extends Object?>(T? p) async => await [p!];
''', [
      lint(60, 1),
    ]);
  }
}
