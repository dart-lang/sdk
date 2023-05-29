// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LiteralOnlyBooleanExpressionsTest);
  });
}

@reflectiveTest
class LiteralOnlyBooleanExpressionsTest extends LintRuleTest {
  @override
  String get lintRule => 'literal_only_boolean_expressions';

  test_ifCase_intLiteral() async {
    await assertDiagnostics(r'''
void f() {
  if (1 case {1:0}) {
    print('');
  }
}
''', [
      // No lint
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 24, 5),
    ]);
  }

  test_ifCase_listLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  if ([1] case [1]) {
    print('');
  }
}
''');
  }

  test_ifCase_mapLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  if ({1:0} case {1:0}) {
    print('');
  }
}
''');
  }

  test_ifCase_objectInstantiation() async {
    await assertNoDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}

void f() {
  if (A(1) case A(a: 1)) {
    print('');
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4352
  test_ifCase_record() async {
    await assertNoDiagnostics(r'''
void f() {
  if (('', '') case (String(), String())) {
    print('');
  }
}
''');
  }

  test_switchExpression() async {
    await assertNoDiagnostics(r'''
bool f(Object o) => switch(o) {
    [1] => true,
    {1:1} => false,
    (1, 1) => false,
    String(isEmpty: false) => false,
    _ => false,
  };
''');
  }

  test_whenClause() async {
    await assertDiagnostics(r'''
void f() {
  switch (1) {
    case [int a] when true: print(a);
  }
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 35, 7),
      lint(43, 9),
    ]);
  }

  test_whileTrue() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {
    print('!');
  }
}
''');
  }
}
