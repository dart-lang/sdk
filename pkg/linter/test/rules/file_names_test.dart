// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileNamesTest);
  });
}

@reflectiveTest
class FileNamesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.file_names;

  test_invalidName() async {
    var testFilePath = convertPath('$testPackageLibPath/a-test.dart');
    newFile(testFilePath, r'''
class A { }
''');

    await assertDiagnosticsInFile(testFilePath, [lint(0, 0)]);
  }

  test_validName() async {
    var testFilePath = convertPath('$testPackageLibPath/non-strict.css.dart');
    newFile(testFilePath, r'''
class A { }
''');
    await assertNoDiagnosticsInFile(testFilePath);
  }
}
