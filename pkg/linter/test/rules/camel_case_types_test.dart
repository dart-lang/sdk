// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CamelCaseTypesTest);
  });
}

@reflectiveTest
class CamelCaseTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'camel_case_types';

  test_extensionType_lowerCase() async {
    // No need to test all the variations. Name checking is shared with other
    // declaration types.
    await assertDiagnostics(r'''
extension type fooBar(int i) {}
''', [
      lint(15, 6),
    ]);
  }

  test_extensionType_wellFormed() async {
    await assertNoDiagnostics(r'''
extension type FooBar(int i) {}
''');
  }
}
