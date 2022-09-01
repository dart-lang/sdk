// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileNamesInvalidTest);
    defineReflectiveTests(FileNamesNonStrictTest);
  });
}

@reflectiveTest
class FileNamesInvalidTest extends LintRuleTest {
  @override
  String get lintRule => 'file_names';

  @override
  String get testFilePath => '$testPackageLibPath/a-test.dart';

  test_invalidName() async {
    await assertDiagnostics(r'''
class A { }
''', [
      lint(0, 0),
    ]);
  }
}

@reflectiveTest
class FileNamesNonStrictTest extends LintRuleTest {
  @override
  String get lintRule => 'file_names';

  @override
  String get testFilePath => '$testPackageLibPath/non-strict.css.dart';

  test_validName() async {
    await assertNoDiagnostics(r'''
class A { }
''');
  }
}
