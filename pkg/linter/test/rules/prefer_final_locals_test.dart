// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalLocalsTest);
  });
}

@reflectiveTest
class PreferFinalLocalsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_final_locals;

  test_destructured_listPattern() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] [a, b] = ['a', 'b'];
}
''');
  }

  test_destructured_listPattern_final() async {
    await assertNoDiagnostics(r'''
f() {
  final [a, b] = [1, 2];
}
''');
  }

  test_destructured_listPattern_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  var [a, b] = [1, 2];
  ++a;
}
''');
  }

  test_destructured_listPattern_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] [_, b] = ['a', 'b'];
}
''');
  }

  test_destructured_listPattern_wildcard_parenthesized() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] [(_), b] = ['a', 'b'];
}
''');
  }

  test_destructured_listPattern_wildcard_single() async {
    await assertNoDiagnostics(r'''
f() {
  var [_] = ['a'];
}
''');
  }

  test_destructured_listPattern_wildcard_single_parenthesized() async {
    await assertNoDiagnostics(r'''
f() {
  var [(_)] = ['a'];
}
''');
  }

  test_destructured_listPatternWithRest() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] [a, b, ...rest] = [1, 2, 3, 4, 5, 6, 7];
}
''');
  }

  test_destructured_listPatternWithRest_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  var [a, b, ...rest] = [1, 2, 3, 4, 5, 6, 7];
  ++a;
}
''');
  }

  test_destructured_mapPattern() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] {'first': a, 'second': b} = {'first': 1, 'second': 2};
}
''');
  }

  test_destructured_mapPattern_final() async {
    await assertNoDiagnostics(r'''
f() {
  final {'first': a, 'second': b} = {'first': 1, 'second': 2};
}
''');
  }

  test_destructured_mapPattern_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  var {'first': a, 'second': b} = {'first': 1, 'second': 2};
  ++a;
}
''');
  }

  test_destructured_mapPattern_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] {'first': a, 'second': _} = {'first': 1, 'second': 2};
}
''');
  }

  test_destructured_mapPattern_wildcard_single() async {
    await assertNoDiagnostics(r'''
f() {
  var {'first': _} = {'first': 1};
}
''');
  }

  test_destructured_objectPattern() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}
f() {
  [!var!] A(a: b) = A(1);
}
''');
  }

  test_destructured_objectPattern_final() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: b) = A(1);
}
''');
  }

  test_destructured_objectPattern_join() async {
    await assertDiagnostics(
      r'''
void fn(Object val) {
  if (val case String(:var isEmpty) || List(:var isEmpty)) {
  }
}
''',
      [
        lint(45, 11, contextMessages: [contextMessage(testFile, 71, 7)]),
      ],
    );
  }

  test_destructured_objectPattern_join_final() async {
    await assertNoDiagnostics(r'''
void fn(Object val) {
  if (val case String(:final isEmpty) || List(:final isEmpty)) {
  }
}
''');
  }

  test_destructured_objectPattern_join_mutated() async {
    await assertNoDiagnostics(r'''
void fn(Object val) {
  if (val case String(:var isEmpty) || List(:var isEmpty)) {
    isEmpty = true;
  }
}
''');
  }

  test_destructured_objectPattern_mutated() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  var A(a: b) = A(1);
  ++b;
}
''');
  }

  test_destructured_objectPattern_wildcard() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  var A(a: _) = A(1);
}
''');
  }

  test_destructured_objectPattern_wildcard_multipleFields() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a, b;
  A(this.a, this.b);
}
f() {
  [!var!] A(a: x, b: _) = A(1, 2);
}
''');
  }

  test_destructured_parenthesizedPattern_wildcard() async {
    await assertNoDiagnostics(r'''
f() {
  var (_) = ('a');
}
''');
  }

  test_destructured_recordPattern() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] (a, b) = ('a', 'b');
}
''');
  }

  test_destructured_recordPattern_final() async {
    await assertNoDiagnostics(r'''
f() {
  final (a, b) = ('a', 'b');
}
''');
  }

  test_destructured_recordPattern_forLoop() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  for (var (/*[0*/a/*0]*/, /*[1*/b/*1]*/) in [(1, 2)]) { }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4286
  test_destructured_recordPattern_forLoop_final() async {
    await assertNoDiagnostics(r'''
f() {
  for (final (a, b) in [(1, 2), (3, 4), (5, 6)]) { }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4539
  test_destructured_recordPattern_forLoop_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  for (var (a, b) in [(1, 2)]) {
    ++a;
  }
}
''');
  }

  test_destructured_recordPattern_forLoop_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  for (var (_, [!b!]) in [(1, 2)]) { }
}
''');
  }

  test_destructured_recordPattern_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (1, 'b');
  ++a;
}
''');
  }

  test_destructured_recordPattern_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] (_, b) = ('a', 'b');
}
''');
  }

  test_destructured_recordPattern_wildcard_multipleWildcards() async {
    await assertNoDiagnostics(r'''
f() {
  var (_, _) = ('a', 'b');
}
''');
  }

  test_destructured_recordPattern_withParenthesizedPattern() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!var!] ((a, b)) = ('a', 'b');
}
''');
  }

  test_field() async {
    await assertNoDiagnostics(r'''
class C {
  int f = 0;
}
''');
  }

  test_ifPatternList() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case [[!int x!], final int y]) x;
}
''');
  }

  test_ifPatternList_final() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case [final int x, final int y]) x;
}
''');
  }

  test_ifPatternList_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case [[!int x!], int _]) x;
}
''');
  }

  test_ifPatternMap() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case {'x': [!var x!]}) print('$x');
}
''');
  }

  test_ifPatternMap_final() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case {'x': final x}) x;
}
''');
  }

  test_ifPatternMap_wildcard() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case {'x': var _});
}
''');
  }

  test_ifPatternObject() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  int c;
  C(this.c);
}

f(Object o) {
  if (o case C(c: [!var x!])) x;
}
''');
  }

  test_ifPatternObject_final() async {
    await assertNoDiagnostics(r'''
class C {
  int c;
  C(this.c);
}

f(Object o) {
  if (o case C(c: final x)) x;
}
''');
  }

  test_ifPatternObject_wildcard() async {
    await assertNoDiagnostics(r'''
class C {
  int c;
  C(this.c);
}

f(Object o) {
  if (o case C(c: var _));
}
''');
  }

  test_ifPatternRecord() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case (/*[0*/int x/*0]*/, /*[1*/int y/*1]*/)) x;
}
''');
  }

  test_ifPatternRecord_final() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (final int x, final int y)) x;
}
''');
  }

  test_ifPatternRecord_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case ([!int x!], int _)) x;
}
''');
  }

  test_nonDeclaration_destructured_recordPattern() async {
    await assertNoDiagnostics(r'''
f(String a, String b) {
  [a, b] = ['a', 'b'];
}
''');
  }

  test_notReassigned_withFinal() async {
    await assertNoDiagnostics(r'''
void f() {
  final a = 'hello';
  print(a);
}
''');
  }

  test_notReassigned_withType_multiple() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!String!] a = 'hello', b = 'world';
  print(a);
  print(b);
}
''');
  }

  test_notReassigned_withVar() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!var!] a = '';
  print(a);
}
''');
  }

  test_notReassigned_withVar_multiple() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!var!] a = 'hello', b = 'world';
  print(a);
  print(b);
}
''');
  }

  test_notReassigned_withVar_wildcard() async {
    await assertNoDiagnostics(r'''
void f() {
  var _ = '';
}
''');
  }

  test_reassigned() async {
    await assertNoDiagnostics(r'''
void f() {
  var a = 'hello';
  a = 'hello world';
}
''');
  }

  test_reassigned_multiple() async {
    await assertNoDiagnostics(r'''
void f() {
  var a = 'hello', b = 'world';
  a = 'world';
}
''');
  }

  test_switch_objectPattern() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && [!var b!]): b;
  }
}
''');
  }

  test_switch_objectPattern_final() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b): b;
  }
}
''');
  }

  test_switch_objectPattern_mutated() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b): ++b;
  }
}
''');
  }

  test_switch_objectPattern_wildcard() async {
    await assertDiagnostics(
      r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var _): print('');
  }
}
''',
      [
        // No lint.
        error(diag.unnecessaryWildcardPattern, 79, 5),
      ],
    );
  }

  test_switch_recordPattern() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ((1, 2)) {
    case (/*[0*/var a/*0]*/, /*[1*/int b/*1]*/): a;
  }
}
''');
  }

  test_switch_recordPattern_final() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, final int b): a;
  }
}
''');
  }

  test_switch_recordPattern_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (var a, final int b): ++a;
  }
}
''');
  }

  test_switch_recordPattern_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ((1, 2)) {
    case ([!var a!], int _): a;
  }
}
''');
  }

  test_wildcardLocal() async {
    await assertNoDiagnostics(r'''
f() {
  var _ = 0;
}
''');
  }
}
