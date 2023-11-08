// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortPubDependenciesTest);
  });
}

@reflectiveTest
class SortPubDependenciesTest extends LintRuleTest {
  @override
  bool get dumpAstOnFailures => false;

  @override
  String get lintRule => 'sort_pub_dependencies';

  test_dependencies_duplicates() async {
    await assertNoPubspecDiagnostics(r'''
name: fancy
version: 1.1.1

dependencies:
  aaa: ^0.1.1
  aaa: ^0.1.1
  bbb: ^0.15.8
  flutter:
    sdk: flutter
''');
  }

  test_dependencies_sorted() async {
    await assertNoPubspecDiagnostics(r'''
name: fancy
version: 1.1.1

dependencies:
  aaa: ^0.1.1
  bbb: ^0.15.8
  flutter:
    sdk: flutter
''');
  }

  test_dependencies_unsorted() async {
    await assertPubspecDiagnostics(r'''
name: fancy
version: 1.1.1

dependencies:
  aaa: ^0.1.1
  flutter:
    sdk: flutter
  bbb: ^0.15.8
''', [
      lint(86, 3),
    ]);
  }

  test_dependencyOverrides_unsorted() async {
    await assertPubspecDiagnostics(r'''
name: fancy
version: 1.1.1

dependency_overrides:
  aaa: ^0.1.1
  flutter:
    sdk: flutter
  bbb: ^0.15.8
''', [
      lint(94, 3),
    ]);
  }

  test_devDependencies_unsorted() async {
    await assertPubspecDiagnostics(r'''
name: fancy
version: 1.1.1

dev_dependencies:
  aaa: ^0.1.1
  flutter:
    sdk: flutter
  bbb: ^0.15.8
''', [
      lint(90, 3),
    ]);
  }
}
