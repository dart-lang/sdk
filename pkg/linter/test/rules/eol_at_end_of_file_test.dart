// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EolAtEndOfFileTest);
  });
}

@reflectiveTest
class EolAtEndOfFileTest extends LintRuleTest {
  @override
  String get lintRule => 'eol_at_end_of_file';

  test_hasEol() async {
    await assertDiagnostics(r'''
class A {}''', [
      lint(10, 1),
    ]);
  }

  test_hasMultipleNewlines() async {
    await assertDiagnostics(r'''
class A {}

''', [
      lint(10, 1),
    ]);
  }

  test_hasNoEol() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }
}
