// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedConsistencyTest);
  });
}

@reflectiveTest
class DeprecatedConsistencyTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.deprecated_consistency;

  test_classDeprecated_factoryConstructor() async {
    await assertDiagnostics(r'''
@deprecated
class A {
  @deprecated
  A._();

  factory A() => A._();
}
''', [
      lint(56, 1),
    ]);
  }

  test_classDeprecated_factoryConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
class A {
  @deprecated
  A._();

  @deprecated
  factory A() => A._();
}
''');
  }

  test_classDeprecated_generativeConstructor() async {
    await assertDiagnostics(r'''
@deprecated
class A {
  A();
}
''', [
      lint(24, 1),
    ]);
  }

  test_classDeprecated_generativeConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
class A {
  @deprecated
  A();
}
''');
  }

  test_constructorFieldFormalDeprecated_field() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  A({@deprecated this.a});
}
''', [
      lint(20, 1),
    ]);
  }

  test_constructorFieldFormalDeprecated_fieldDeprecated() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  String? a;
  A({@deprecated this.a});
}
''');
  }

  test_constructorSuperFieldFormalDeprecated_field() async {
    await assertNoDiagnostics(r'''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({@deprecated super.a});
}
''');
  }

  test_fieldDeprecated_fieldFormalParameter() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  String? a;
  A({this.a});
}
''', [
      lint(42, 6),
    ]);
  }

  test_fieldDeprecated_fieldFormalParameter_deprecated() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  String? a;
  A({@deprecated this.a});
}
''');
  }
}
