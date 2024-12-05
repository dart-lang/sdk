// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryLibraryNameTest);
  });
}

@reflectiveTest
class UnnecessaryLibraryNameTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_library_name;

  test_namedLibrary() async {
    await assertDiagnostics(r'''
library name;
''', [
      lint(8, 4),
    ]);
  }

  test_namedLibrary_preUnnamedLibraries() async {
    await assertNoDiagnostics(r'''
// @dart = 2.14
library name;
''');
  }

  test_unnamedLibrary() async {
    await assertNoDiagnostics(r'''
library;
''');
  }
}
