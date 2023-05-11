// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalFieldsTest);
  });
}

@reflectiveTest
class PreferFinalFieldsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_final_fields';

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int _x = 0;
  int get x => _x;
}
''', [
      // No Lint.
      error(CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM, 24, 2),
    ]);
  }

  test_overrideField_extends() async {
    await assertNoDiagnostics(r'''
class A {
  bool _a = false;
  void m() {
    _a = true;
    print(_a);
  }
}

class B extends A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3760
  test_overrideField_implements() async {
    await assertNoDiagnostics(r'''
class A {
  bool _a = false;
  void m() {
    _a = true;
    print(_a);
  }
}

class B implements A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  test_overrideSetter_extends() async {
    await assertNoDiagnostics(r'''
class A {
  set _a(bool a) {}
  void m() {
    _a = true;
  }
}

class B extends A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  test_overrideSetter_implements() async {
    await assertNoDiagnostics(r'''
class A {
  set _a(bool a) {}
  void m() {
    _a = true;
  }
}

class B implements A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }
}
