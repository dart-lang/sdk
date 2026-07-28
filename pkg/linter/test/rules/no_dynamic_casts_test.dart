// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDynamicCastsTest);
  });
}

@reflectiveTest
class NoDynamicCastsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_dynamic_casts;

  test_argument() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {}
void g(dynamic a) {
  f([!a!]);
}
''');
  }

  test_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  int x = [!a!];
}
''');
  }

  test_assignment_ok() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  dynamic x = a;
  Object? y = a;
}
''');
  }

  test_condition_conditionalExpression() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  [!a!] ? 1 : 2;
}
''');
  }

  test_condition_doLoop() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  do {} while ([!a!]);
}
''');
  }

  test_condition_forLoop() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  for (; [!a!];) {}
}
''');
  }

  test_condition_ifExpression() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  [if ([!a!]) 7];
}
''');
  }

  test_condition_ifStatement() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  if ([!a!]) {}
}
''');
  }

  test_condition_whileLoop() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  while ([!a!]) {}
}
''');
  }

  test_explicitCast_ok() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  int x = a as int;
}
''');
  }

  test_expressionFunctionBody() async {
    await assertDiagnosticsFromMarkup(r'''
int f(dynamic a) => [!a!];
''');
  }

  test_forEach_iterable() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  for (var x in [!a!]) {}
}
''');
  }

  test_forEach_variable() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<dynamic> list) {
  for (int x in [!list!]) {}
}
''');
  }

  test_forEach_variable_objectQuestionTarget() async {
    await assertNoDiagnostics(r'''
void f(List<dynamic> list) {
  for (Object? x in list) {}
}
''');
  }

  test_listLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var list = <int>[[!a!]];
}
''');
  }

  test_logicalBinary_left() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a, bool b) {
  [!a!] && b;
}
''');
  }

  test_logicalBinary_right() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool a, dynamic b) {
  a && [!b!];
}
''');
  }

  test_mapLiteral_key() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var map = <int, String>{[!a!]: 'x'};
}
''');
  }

  test_mapLiteral_spread() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var map = <String, int>{...[!a!]};
}
''');
  }

  test_mapLiteral_value() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var map = <String, int>{'x': [!a!]};
}
''');
  }

  test_namedArgument() async {
    await assertDiagnosticsFromMarkup(r'''
void f({required int x}) {}
void g(dynamic a) {
  f(x: [!a!]);
}
''');
  }

  test_negation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  ![!a!];
}
''');
  }

  test_return() async {
    await assertDiagnosticsFromMarkup(r'''
int f(dynamic a) {
  return [!a!];
}
''');
  }

  test_return_async() async {
    await assertDiagnosticsFromMarkup(r'''
Future<int> f(dynamic a) async {
  return [!a!];
}
''');
  }

  test_setLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var set = <int>{[!a!]};
}
''');
  }

  test_spreadList() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a) {
  var list = <int>[...[!a!]];
}
''');
  }

  test_yield() async {
    await assertDiagnosticsFromMarkup(r'''
Iterable<int> f(dynamic a) sync* {
  yield [!a!];
}
''');
  }

  test_yieldStar() async {
    await assertDiagnosticsFromMarkup(r'''
Iterable<int> f(dynamic a) sync* {
  yield* [!a!];
}
''');
  }
}
