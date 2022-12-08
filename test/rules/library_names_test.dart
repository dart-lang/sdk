// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryNamesTest);
  });
}

@reflectiveTest
class LibraryNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'library_names';

  test_libraryWithoutName() async {
    await assertNoDiagnostics('''
library;
''');
  }

  test_lowercase() async {
    await assertNoDiagnostics('''
library foo;
''');
  }

  test_noLibrary() async {
    await assertNoDiagnostics('''
''');
  }

  test_titlecase() async {
    await assertDiagnostics('''
library Foo;
''', [
      lint(8, 3),
    ]);
  }

  test_uppercaseInDots() async {
    await assertDiagnostics('''
library one.Two.three;
''', [
      lint(8, 13),
    ]);
  }
}
