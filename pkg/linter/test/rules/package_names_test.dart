// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageNamesTest);
  });
}

@reflectiveTest
class PackageNamesTest extends LintRuleTest {
  @override
  bool get dumpAstOnFailures => false;

  @override
  String get lintRule => LintNames.package_names;

  test_lowerCamelCase() async {
    await assertPubspecDiagnostics(r'''
name: fooBar
version: 0.0.1
''', [
      lint(6, 6),
    ]);
  }

  test_oneUpperWord() async {
    await assertPubspecDiagnostics(r'''
name: Foo
version: 0.0.1
''', [
      lint(6, 3),
    ]);
  }

  test_oneWord() async {
    await assertNoPubspecDiagnostics(
      r'''
name: foo
version: 0.0.1
''',
    );
  }

  test_snakeCase() async {
    await assertNoPubspecDiagnostics(r'''
name: foo_bar
version: 0.0.1
''');
  }

  test_upperCamelCase() async {
    await assertPubspecDiagnostics(r'''
name: FooBar
version: 0.0.1
''', [
      lint(6, 6),
    ]);
  }
}
