// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentIgnoresTest);
  });
}

@reflectiveTest
class DocumentIgnoresTest extends LintRuleTest {
  @override
  String get lintRule => 'document_ignores';

  test_precedingDeclaration_notDocumented() async {
    await assertDiagnostics(
      r'''
int x = 0;

// ignore: unused_element
int _y = 0;
''',
      [
        lint(12, 25),
      ],
    );
  }

  test_precedingLine_butIsTrailing_notDocumented() async {
    await assertDiagnostics(
      r'''
int x = 0; // Text.
// ignore: unused_element
int _y = 0;
''',
      [
        lint(20, 25),
      ],
    );
  }

  test_precedingLine_documented() async {
    await assertNoDiagnostics(r'''
// Text.
// ignore: unused_element
int _y = 0;
''');
  }

  test_precedingLine_ignoreIsTrailing_documented() async {
    await assertNoDiagnostics(r'''
// Text.
int _y = 0; // ignore: unused_element
''');
  }

  test_precedingLine_multiple_documented() async {
    await assertNoDiagnostics(r'''
// Text.
// ignore_for_file: unused_element
// Text.
// ignore_for_file: unnecessary_cast
int _y = 0 as int;
''');
  }

  test_precedingLine_multiple_notDocumented() async {
    await assertDiagnostics(
      r'''
// Text.
// ignore_for_file: unused_element

// ignore_for_file: unnecessary_cast
int _y = 0 as int;
''',
      [
        lint(45, 36),
      ],
    );
  }

  test_sameComment_comma_documented() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element, I need this
int _y = 0;
''');
  }

  test_sameComment_whitespace_documented() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element http://linter-bug
int _y = 0;
''');
  }
}
