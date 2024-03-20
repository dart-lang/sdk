// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryLibraryNamesTest);
  });
}

@reflectiveTest
class UnnecessaryLibraryNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_library_names';

  test_namedLibrary() async {
    await assertDiagnostics(r'''
library name;
''', [
      lint(8, 4),
    ]);
  }

  test_unnamedLibrary() async {
    await assertNoDiagnostics(r'''
library;
''');
  }
}
