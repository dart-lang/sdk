// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryParenthesisTest);
    defineReflectiveTests(UnnecessaryParenthesisPatternsTest);
  });
}

@reflectiveTest
class UnnecessaryParenthesisPatternsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_parenthesis';

  /// https://github.com/dart-lang/linter/issues/4060
  test_constantPattern() async {
    await assertNoDiagnostics(r'''
const a = 1;
const b = 2;

void f(int i) {
  switch (i) {
    case const (a + b):
  }
}
''');
  }
}

@reflectiveTest
class UnnecessaryParenthesisTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_parenthesis';

  /// https://github.com/dart-lang/linter/issues/4041
  test_nullAware_cascadeAssignment() async {
    await assertNoDiagnostics(r'''    
class A {
  var b = false;
  void m() {}
  set setter(int i) {}
}

void f(A? a) {
  (a?..b = true)?.m();
  (a?..b = true)?.setter = 1;
}

void g(List<int>? list) {
  (list?..[0] = 1)?.length;
}
''');
  }
}
