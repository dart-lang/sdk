// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullChecksTest);
  });
}

@reflectiveTest
class UnnecessaryNullChecksTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_null_checks';

  test_assignment_await_nullableTarget() async {
    await assertDiagnostics(r'''
Future<void> f(int? p, int? i, Future<int?> future) async {
  i = await future!;
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 78, 1),
      lint(78, 1),
    ]);
  }

  test_assignment_nullable() async {
    await assertDiagnostics(r'''
void f(int? v, int? i) {
  v = i!;
}
''', [
      lint(32, 1),
    ]);
  }

  test_assignment_nullable_self() async {
    await assertNoDiagnostics(r'''
void f(int? v) {
  int? v;
  v = v!;
}
''');
  }

  test_assignment_nullableTarget() async {
    await assertDiagnostics(r'''
int? j = i!;
int? i;
''', [
      lint(10, 1),
    ]);
  }

  test_assignment_nullableTarget_parenthesized() async {
    await assertDiagnostics(r'''
int? j2 = (i!);
int? i;
''', [
      lint(12, 1),
    ]);
  }

  test_binaryOperator_argument() async {
    await assertDiagnostics(r'''
class A {
  operator +(int? p) => A() + p!;
}
''', [
      lint(41, 1),
    ]);
  }

  test_completerComplete() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(int? i) => Completer<int>().complete(i!);
''');
  }

  test_compoundAssignment_promotedToNonNullable() async {
    await assertNoDiagnostics(r'''
void f(int? v, int? p) {
  v ??= 1;
  v += p!;
}
''');
  }

  test_constructorCall_optionalPositionalArgument() async {
    await assertDiagnostics(r'''
class A {
  A([int? p]);
}
void f(int? i) => A(i!);
''', [
      lint(48, 1),
    ]);
  }

  test_functionCall_namedArgument() async {
    await assertDiagnostics(r'''
void f({int? p, int? i}) => f(p: i!);
''', [
      lint(34, 1),
    ]);
  }

  test_functionCall_positionalArgument() async {
    await assertDiagnostics(r'''
int? i;
void f(int? p) => f(i!);
''', [
      lint(29, 1),
    ]);
  }

  test_functionCall_positionalArgument_parenthesized() async {
    await assertDiagnostics(r'''
int? i;
void f(int? p) => f((i!));
''', [
      lint(30, 1),
    ]);
  }

  test_futureValue() async {
    await assertNoDiagnostics(r'''
void f(int? i) => Future<int>.value(i!);
''');
  }

  test_listPattern() async {
    await assertDiagnostics(r'''
void f(int? a, int? b) {
  [b!, ] = [a, ];
}
''', [
      lint(29, 1),
    ]);
  }

  test_nullableAssignment_nullable() async {
    await assertNoDiagnostics(r'''
void f(int? v, int? p) {
  v ??= p!;
}
''');
  }

  test_recordPattern() async {
    await assertDiagnostics(r'''
void f(int? a, int? b) {
  (b!, ) = (a, );
}
''', [
      lint(29, 1),
    ]);
  }

  test_return_function_dynamic() async {
    // TODO(srawlins): Why does a dynamic-returning function result in a
    // diagnostic, but a dynamic-returning method does not?
    await assertDiagnostics(r'''
dynamic f(int? p) {
  return p!;
}
''', [
      lint(30, 1),
    ]);
  }

  test_return_list_nonNullable() async {
    await assertNoDiagnostics(r'''
List<int> f7ok(int? p) => [p!];
''');
  }

  test_return_list_nullable() async {
    await assertDiagnostics(r'''
List<int?> f7(int? p) => [p!];
''', [
      lint(27, 1),
    ]);
  }

  test_return_mapKey_nonNullable() async {
    await assertNoDiagnostics(r'''
Map<int, String> f(int? p) => {p!: ''};
''');
  }

  test_return_mapKey_nullable() async {
    await assertDiagnostics(r'''
Map<int?, String> f(int? p) => {p!: ''};
''', [
      lint(33, 1),
    ]);
  }

  test_return_mapValue_forElement_nonNullable() async {
    await assertNoDiagnostics(r'''
Map<String, int> f(int? p) => {for (var a in <int>[]) '': p!};
''');
  }

  test_return_mapValue_forElement_nullable() async {
    await assertDiagnostics(r'''
Map<String, int?> f(int? p) => {for (var a in <int>[]) '': p!};
''', [
      lint(60, 1),
    ]);
  }

  test_return_mapValue_ifElement_nonNullable() async {
    await assertNoDiagnostics(r'''
Map<String, int> f(int? p) => {if (1 != 0) '': p!}; // OK
''');
  }

  test_return_mapValue_ifElement_nullable() async {
    await assertDiagnostics(r'''
Map<String, int?> f(int? p) => {if (1 != 0) '': p!};
''', [
      lint(49, 1),
    ]);
  }

  test_return_mapValue_ifElementNested_nullable() async {
    await assertDiagnostics(r'''
Map<String, int?> f(int? p) => {if (1 != 0) if (1 != 0) '': p!};
''', [
      lint(61, 1),
    ]);
  }

  test_return_mapValue_nonNullable() async {
    await assertNoDiagnostics(r'''
Map<String, int> f(int? p) => {'': p!};
''');
  }

  test_return_mapValue_nullable() async {
    await assertDiagnostics(r'''
Map<String, int?> f(int? p) => {'': p!};
''', [
      lint(37, 1),
    ]);
  }

  test_return_method_dynamic() async {
    await assertNoDiagnostics(r'''
class A {
  dynamic f(int? p) {
    return p!;
  }
}
''');
  }

  test_return_nullable() async {
    await assertDiagnostics(r'''
int? f(int? i) { return i!; }
''', [
      lint(25, 1),
    ]);
  }

  test_return_set_nonNullable() async {
    await assertNoDiagnostics(r'''
Set<int> f(int? p) => {p!};
''');
  }

  test_return_set_nullable() async {
    await assertDiagnostics(r'''
Set<int?> f(int? p) => {p!};
''', [
      lint(25, 1),
    ]);
  }

  test_returnAsync_dynamic() async {
    await assertNoDiagnostics(r'''
dynamic f(int? p) async => p!;
''');
  }

  test_returnAsync_futureOfNonNullable() async {
    await assertNoDiagnostics(r'''
Future<int> f15ok(int? p) async => p!;
''');
  }

  test_returnAsync_futureOfNonNullable_await() async {
    await assertNoDiagnostics(r'''
Future<int> f(int? p) async => await p!;
''');
  }

  test_returnAsync_futureOfNonNullable_typedef() async {
    await assertNoDiagnostics(r'''
typedef F = Future<int>;
F f(int? p) async => p!;
''');
  }

  test_returnAsync_futureOfNullable() async {
    await assertDiagnostics(r'''
Future<int?> f(int? p) async => p!;
''', [
      lint(33, 1),
    ]);
  }

  test_returnAsync_futureOfNullable_await() async {
    await assertDiagnostics(r'''
Future<int?> f(int? p) async => await p!;
''', [
      lint(39, 1),
    ]);
  }

  test_returnAsync_futureOfNullable_typedef() async {
    await assertDiagnostics(r'''
typedef F = Future<int?>;
F f(int? p) async => p!;
''', [
      lint(48, 1),
    ]);
  }

  test_returnExpressionBody_nullable() async {
    await assertDiagnostics(r'''
int? f(int? i) => i!;
''', [
      lint(19, 1),
    ]);
  }

  test_undefinedFunction() async {
    await assertDiagnostics(r'''
f6(int? p) {
  return B() + p!; // OK
}
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 22, 1),
    ]);
  }

  test_yieldAsyncStar_streamOfNonNullable() async {
    await assertNoDiagnostics(r'''
Stream<int> f13ok(int? p) async* {yield p!;}
''');
  }

  test_yieldAsyncStar_streamOfNullable() async {
    await assertDiagnostics(r'''
Stream<int?> f(int? p) async* {yield p!;}
''', [
      lint(38, 1),
    ]);
  }

  test_yieldSyncStar_iterableOfNonNullable() async {
    await assertNoDiagnostics(r'''
Iterable<int> f(int? p) sync* {yield p!;}
''');
  }

  test_yieldSyncStar_iterableOfNullable() async {
    await assertDiagnostics(r'''
Iterable<int?> f(int? p) sync* {yield p!;}
''', [
      lint(39, 1),
    ]);
  }
}
