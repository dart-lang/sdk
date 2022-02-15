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
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'avoid_equals_and_hash_code_on_mutable_classes';

  @FailingTest(
      issue: 'https://github.com/dart-lang/linter/issues/3094',
      reason: 'Needs new analyzer')
  test_enums() async {
    // Enums are constant by design.
    await assertNoDiagnostics(r'''
enum E {
  e(1), f(2), g(3);
  final int key;
  const E(this.key);
  bool operator ==(Object other) => other is E && other.key == key;
  int get hashCode => key.hashCode;
}
''');
  }
}
