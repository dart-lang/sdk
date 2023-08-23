// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CamelCaseExtensionsTest);
  });
}

@reflectiveTest
class CamelCaseExtensionsTest extends LintRuleTest {
  @override
  String get lintRule => 'camel_case_extensions';

  test_lowerCase() async {
    await assertDiagnostics(r'''
extension fooBar on Object {}
''', [
      lint(10, 6),
    ]);
  }

  test_underscore() async {
    await assertDiagnostics(r'''
extension Foo_Bar on Object { }
''', [
      lint(10, 7),
    ]);
  }

  test_unnamed() async {
    await assertNoDiagnostics(r'''
extension on Object { }
''');
  }

  test_wellFormed() async {
    await assertNoDiagnostics(r'''
extension FooBar on Object { }
''');
  }
}
