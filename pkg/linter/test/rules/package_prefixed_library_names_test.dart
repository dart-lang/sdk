// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackagePrefixedLibraryNamesTest);
  });
}

@reflectiveTest
class PackagePrefixedLibraryNamesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.package_prefixed_library_names;

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3395')
  test_badName() async {
    await assertDiagnostics(r'''
library linter.not_where_it_should_be;
''', [
      lint(8, 29),
    ]);
  }
}
