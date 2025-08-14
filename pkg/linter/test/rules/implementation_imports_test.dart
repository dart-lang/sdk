// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementationImportsTest);
  });
}

@reflectiveTest
class ImplementationImportsTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => LintNames.implementation_imports;
  test_inPartFile() async {
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnostics(
      r'''
part of 'a.dart';

import 'package:flutter/src/material/colors.dart';
''',
      [error(WarningCode.unusedImport, 26, 42), lint(26, 42)],
    );
  }
}
