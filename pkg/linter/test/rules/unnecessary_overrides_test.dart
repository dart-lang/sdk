// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryOverridesTest);
  });
}

@reflectiveTest
class UnnecessaryOverridesTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_overrides';

  test_enum_field() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  Type get runtimeType => super.runtimeType;
}
''', [
      lint(41, 11),
    ]);
  }

  test_enum_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  String toString() => super.toString();
}
''', [
      lint(39, 8),
    ]);
  }

  test_method_ok_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  void a() { }
}

class B extends A {
  @override
  void a() {
    // There's something we want to document here.
    super.a();
  }
}
''');
  }

  test_method_ok_expressionStatement_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  void a() { }
}

class B extends A {
  @override
  void a() =>
    // There's something we want to document here.
    super.a();
}
''');
  }

  test_method_ok_returnExpression_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  @override
  String toString() {
    // There's something we want to document here.
    return super.toString();
  }
}
''');
  }
}
