// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyConstructorBodiesTest);
  });
}

@reflectiveTest
class EmptyConstructorBodiesTest extends LintRuleTest {
  @override
  String get lintRule => 'empty_constructor_bodies';

  test_empty() async {
    await assertDiagnostics(r'''
class A {
  A() {}
}
''', [
      lint(16, 2),
    ]);
  }

  test_empty_withComment() async {
    await assertNoDiagnostics(r'''
class A {
  A() {
    // Comments make this OK!
  }
}
''');
  }

  test_noBody() async {
    await assertNoDiagnostics(r'''
class A {
  A();
}
''');
  }

  test_noBody_parameters() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
''');
  }

  test_notEmpty() async {
    await assertNoDiagnostics(r'''
class A {
  A() {
    print('hi');
  }
}
''');
  }
}
