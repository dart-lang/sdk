// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryUnderscoresTest);
  });
}

@reflectiveTest
class UnnecessaryUnderscoresTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_underscores';

  test_enum_field_unused() async {
    await assertDiagnostics(
      r'''
enum E {
  __,
}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_FIELD, 11, 2),
      ],
    );
  }

  test_field_unused() async {
    await assertDiagnostics(
      r'''
class C {
  int __ = 0;
}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_FIELD, 16, 2),
      ],
    );
  }

  test_forPart_unused() async {
    await assertDiagnostics(
      r'''
void f() {
  for (var __ = 0; ; ) {}
}
''',
      [lint(22, 2)],
    );
  }

  test_forPart_used() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var __ = 0; ; ++__) {}
}
''');
  }

  test_function_parameter_unused() async {
    await assertDiagnostics(
      r'''
void f(int _, int __) {}
''',
      [lint(18, 2)],
    );
  }

  test_function_parameter_unused_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6

void f(int _, int __) {}
''');
  }

  test_function_parameter_used() async {
    await assertNoDiagnostics(r'''
void f(int _, int __) {
  print(__);
}
''');
  }

  test_local_unused() async {
    await assertDiagnostics(
      r'''
void f() {
  var __ = 0;
}
''',
      [lint(17, 2)],
    );
  }

  test_local_used() async {
    await assertNoDiagnostics(r'''
void f() {
  var __ = 0;
  print(__);
}
''');
  }

  test_localFunction_parameter_unused() async {
    await assertDiagnostics(
      r'''
void f() {
  g(int __) {}
}
''',
      [error(WarningCode.UNUSED_ELEMENT, 13, 1), lint(19, 2)],
    );
  }

  test_localFunction_parameter_used() async {
    await assertDiagnostics(
      r'''
void f() {
  g(int __) {
    print(__);
  }
}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_ELEMENT, 13, 1),
      ],
    );
  }

  test_localFunction_unused() async {
    await assertDiagnostics(
      r'''
f() {
  __() {}
}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_ELEMENT, 8, 2),
      ],
    );
  }

  test_method_unused() async {
    await assertDiagnostics(
      r'''
class A {
  __() {}
}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_ELEMENT, 12, 2),
      ],
    );
  }

  test_topLevelFunction_unused() async {
    await assertDiagnostics(
      r'''
__() {}
''',
      [
        // No lint.
        error(WarningCode.UNUSED_ELEMENT, 0, 2),
      ],
    );
  }

  test_topLevelVariable_unused() async {
    await assertDiagnostics(
      r'''
int __ = 0;
''',
      [
        // No lint.
        error(WarningCode.UNUSED_ELEMENT, 4, 2),
      ],
    );
  }
}
