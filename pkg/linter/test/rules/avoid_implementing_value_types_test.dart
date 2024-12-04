// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidImplementingValueTypesTest);
  });
}

@reflectiveTest
class AvoidImplementingValueTypesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_implementing_value_types;

  test_classMixinInMixinWithEqualEqual() async {
    await assertNoDiagnostics(r'''
mixin M {
  @override
  bool operator ==(Object o) => false;
}

class C with M {}
''');
  }

  test_declaresEqualEqual() async {
    await assertNoDiagnostics(r'''
class C {
  @override
  bool operator ==(Object o) => false;
}
''');
  }

  test_extendsClassWithEqualEqual() async {
    await assertNoDiagnostics(r'''
class A {
  @override
  bool operator ==(Object o) => false;
}

class C extends A {}
''');
  }

  test_implementsClass_indirectlyWithEqualEqual() async {
    await assertDiagnostics(r'''
class A {
  @override
  bool operator ==(Object o) => false;
}

class B extends A {}

class C implements B {}
''', [
      lint(105, 1),
    ]);
  }

  test_implementsClassWithEqualEqual() async {
    await assertDiagnostics(r'''
class A {
  @override
  bool operator ==(Object o) => false;
}
class C implements A {}
''', [
      lint(82, 1),
    ]);
  }

  test_implementsClassWithoutEqualEqual() async {
    await assertNoDiagnostics(r'''
class A {}
class C implements A {}
''');
  }

  test_mixin() async {
    await assertNoDiagnostics(r'''
mixin M {
  @override
  bool operator ==(Object o) => false;
}
''');
  }
}
