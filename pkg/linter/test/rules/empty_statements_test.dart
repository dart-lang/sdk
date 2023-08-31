// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyStatementsTest);
  });
}

@reflectiveTest
class EmptyStatementsTest extends LintRuleTest {
  @override
  String get lintRule => 'empty_statements';

  test_emptyFor() async {
    await assertDiagnostics(r'''
void f(bool b) {
  for ( ; b; );
}
''', [
      lint(31, 1),
    ]);
  }

  test_emptyIf_followedByBlock() async {
    await assertDiagnostics(r'''
void f(bool b) {
  if (b);
  {
    print(b);
  }
}
''', [
      lint(25, 1),
    ]);
  }

  test_emptyIf_followedByStatement() async {
    await assertDiagnostics(r'''
void f(bool b) {
  if (b);
    print(b);
}
''', [
      lint(25, 1),
    ]);
  }

  test_emptyWhile() async {
    await assertDiagnostics(r'''
void f(bool b) {
  while (b);
}
''', [
      lint(28, 1),
    ]);
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
    await assertDiagnostics(r'''
f() {
  switch(true) {
    case true :
      ;
      ;
      ;
    case false :
      print('');
    }
}
''', [
      lint(45, 1),
      lint(53, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading() async {
    await assertDiagnostics(r'''
f() {
  switch(true) {
    case true :
      ;
      print('');
    case false :
      print('');
    }
}
''', [
      lint(45, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading_trailing() async {
    await assertDiagnostics(r'''
f() {
  switch(true) {
    case true :
      ;
      ;
    case false :
      print('');
    }
}
''', [
      lint(45, 1),
    ]);
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
    await assertDiagnostics(r'''
f() {
  switch(true) {
    case true :
      print('');
      ;
    case false :
      print('');
    }
}
''', [
      lint(62, 1),
    ]);
  }
}
