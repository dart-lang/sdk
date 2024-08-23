// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoWildcardVariableUsesTest);
  });
}

@reflectiveTest
class NoWildcardVariableUsesTest extends LintRuleTest {
  @override
  String get lintRule => 'no_wildcard_variable_uses';

  test_constructor() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  C._();
  m() {
    print(C._);
    print(C._());
  }
}
''');
  }

  test_declaredIdentifier() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  for (var _ in [1, 2, 3]) ;
}
''');
  }

  test_field() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  int _ = 0;
  m() {
    print(_);
  }
}
''');
  }

  test_getter() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  int get _ => 0;
  m() {
    print(_);
  }
}
''');
  }

  test_localVar() async {
    await assertDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)
f() {
  var _ = 1;
  print(_);
}
''', [
      lint(70, 1),
    ]);
  }

  test_localVar_wildcardsEnabled() async {
    // Ensure no lint.
    await assertNoDiagnostics(r'''
f() {
  var _ = 1;
}
''');
  }

  test_method() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  String _() => '';
  m() {
    print(_);
    print(_());
  }
}
''');
  }

  test_param() async {
    await assertDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f(int __) {
  print(__);
}
''', [
      lint(64, 2),
    ]);
  }

  test_topLevelFunction() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

String _() => '';

f() {
  print(_);
  print(_());
}
''');
  }

  test_topLevelGetter() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

int get _ => 0;

f() {
  print(_);
}
''');
  }
}
