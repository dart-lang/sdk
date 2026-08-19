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

  test_ifCase_element_ok() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  [if (a case String s) s];
}
''');
  }

  test_ifCase_element_when() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a, dynamic b) {
  [if (a case String s when [!b!]) s];
}
''');
  }

  test_ifCase_ok() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  if (a case String s) {
    print(s);
  }
}
''');
  }

  test_ifCase_when() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic a, dynamic b) {
  if (a case String s when [!b!]) {
    print(s);
  }
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

  test_patternAssignment_list() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
  String a, b;
  [a, b] = [/*[0*/p/*0]*/, /*[1*/q/*1]*/];
}
''');
  }

  @FailingTest(reason: 'Not implemented yet')
  test_patternAssignment_recordDeconstruction_fromExpression() async {
    await assertDiagnosticsFromMarkup(r'''
void f((dynamic, dynamic) r) {
  String a, b;
  (a, b) = [!r!];
}
''');
  }

  test_patternAssignment_recordDeconstruction_fromLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
 String a, b;
 (a, b) = (/*[0*/p/*0]*/, /*[1*/q/*1]*/);
}
''');
  }

  test_patternAssignment_recordDeconstruction_fromLiteral_named() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
 String a, b;
 (first: a, second: b) = (first: /*[0*/p/*0]*/, second: /*[1*/q/*1]*/);
}
''');
  }

  test_patternAssignment_recordVariable_fromLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q, (int, int) r) {
  r = (/*[0*/p/*0]*/, /*[1*/q/*1]*/);
}
''');
  }

  test_recordLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
 (String, String) r = (/*[0*/p/*0]*/, /*[1*/q/*1]*/);
}
''');
  }

  test_recordLiteral_named() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
 ({String first, int second}) r = (first: /*[0*/p/*0]*/, second: /*[1*/q/*1]*/);
}
''');
  }

  test_recordLiteral_nested() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p, dynamic q) {
 ((String, int), bool) r = ((/*[0*/p/*0]*/, /*[1*/q/*1]*/), true);
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
