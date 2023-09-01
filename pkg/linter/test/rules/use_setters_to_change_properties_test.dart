// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Add test with setter-like with multiple statements; add
    // test with non-trivial right side (`this.x = x + 1`).
    defineReflectiveTests(UseSettersToChangePropertiesTest);
  });
}

@reflectiveTest
class UseSettersToChangePropertiesTest extends LintRuleTest {
  @override
  String get lintRule => 'use_setters_to_change_properties';

  test_abstract() async {
    await assertNoDiagnostics(r'''
abstract class A {
  void setX(int x);
}
''');
  }

  test_combo() async {
    await assertNoDiagnostics(r'''
abstract class A {
  int x = 0;
  void setX(int x) => this.x += x;
}
''');
  }

  test_extension() async {
    await assertDiagnostics(r'''
class A {
  int x = 0;
}

extension E on A {
  void setX(int x) {
    this.x = x;
  }
}
''', [
      lint(52, 4),
    ]);
  }

  test_inheritedFromSuperclass() async {
    await assertNoDiagnostics(r'''
abstract class A {
  void setX(int x);
}

class B extends A {
  int x = 0;

  void setX(int x) {
    this.x = x;
  }
}
''');
  }

  test_inheritedFromSuperInterface() async {
    await assertNoDiagnostics(r'''
abstract class A {
  void setX(int x);
}

class B implements A {
  int x = 0;

  void setX(int x) {
    this.x = x;
  }
}
''');
  }

  test_setterLike_blockBody() async {
    await assertDiagnostics(r'''
abstract class A {
  int x = 0;
  void setX(int x) {
    this.x = x;
  }
}
''', [
      lint(39, 4),
    ]);
  }

  test_setterLike_expressionBody() async {
    await assertDiagnostics(r'''
abstract class A {
  int x = 0;
  void setX(int x) => this.x = x;
}
''', [
      lint(39, 4),
    ]);
  }
}
