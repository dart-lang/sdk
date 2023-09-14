// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEqualsAndHashCodeOnMutableClassesTest);
  });
}

@reflectiveTest
class AvoidEqualsAndHashCodeOnMutableClassesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;
  @override
  String get lintRule => 'avoid_equals_and_hash_code_on_mutable_classes';

  test_enums() async {
    await assertDiagnostics(r'''
enum E {
  e(1), f(2), g(3);
  final int key;
  const E(this.key);
  bool operator ==(Object other) => other is E && other.key == key;
  int get hashCode => key.hashCode;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 83, 2),
      error(CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 145,
          8),
      // No lint.
    ]);
  }

  test_immutableClass() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class A {
  final String key;
  const A(this.key);
  @override
  operator ==(other) => other is A && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
''');
  }

  test_mutableClass() async {
    await assertDiagnostics(r'''
class A {
  final String key;
  const A(this.key);
  @override
  operator ==(other) => other is A && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
''', [
      lint(65, 8),
      lint(133, 3),
    ]);
  }

  test_subtypeOfImmutableClass() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class A {
  const A();
}

class B extends A {
  final String key;
  const B(this.key);
  @override
  operator ==(other) => other is B && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
''');
  }
}
