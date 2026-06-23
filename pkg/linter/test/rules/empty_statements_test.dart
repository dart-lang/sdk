// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyStatementsTest);
  });
}

@reflectiveTest
class EmptyStatementsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.empty_statements;

  test_emptyFor() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool b) {
  for ( ; b; )[!;!]
}
''');
  }

  test_emptyIf_followedByBlock() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool b) {
  if (b)[!;!]
  {
    print(b);
  }
}
''');
  }

  test_emptyIf_followedByStatement() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool b) {
  if (b)[!;!]
    print(b);
}
''');
  }

  test_emptyWhile() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool b) {
  while (b)[!;!]
}
''');
  }

  test_nonEmptyIf_emptyBlock() async {
    await assertNoDiagnostics(r'''
void f(bool b) {
  if (b) {}
}
''');
  }

  test_nonEmptyWhile_emptyBlock() async {
    await assertNoDiagnostics(r'''
void f(bool b) {
  while (b) {}
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_justEmpties() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch(true) {
    case true :
      /*[0*/;/*0]*/
      /*[1*/;/*1]*/
      ;
    case false :
      print('');
    }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch(true) {
    case true :
      [!;!]
      print('');
    case false :
      print('');
    }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading_trailing() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch(true) {
    case true :
      [!;!]
      ;
    case false :
      print('');
    }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_only() async {
    await assertNoDiagnostics(r'''
f() {
  switch(true) {
    case true :
      ;
    case false :
      print('');
    }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_trailing() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch(true) {
    case true :
      print('');
      [!;!]
    case false :
      print('');
    }
}
''');
  }
}
