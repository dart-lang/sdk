// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertDocumentationIntoLineTest);
  });
}

@reflectiveTest
class ConvertDocumentationIntoLineTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE;

  Future<void> test_alreadyLine() async {
    await resolveTestCode('''
/// AAAAAAA
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  Future<void> test_hasEmptyLine() async {
    await resolveTestCode('''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   *
   * BBBBBBBB BBBB BBBB
   */
  mmm() {}
}
''');
    await assertHasAssistAt('AAA [', '''
class A {
  /// AAAAAAA [int] AAAAAAA
  ///
  /// BBBBBBBB BBBB BBBB
  mmm() {}
}
''');
  }

  Future<void> test_notDocumentation() async {
    await resolveTestCode('''
/* AAAA */
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  Future<void> test_onReference() async {
    await resolveTestCode('''
/**
 * AAAAAAA [int] AAAAAAA
 */
class A {}
''');
    await assertHasAssistAt('nt]', '''
/// AAAAAAA [int] AAAAAAA
class A {}
''');
  }

  Future<void> test_onText() async {
    await resolveTestCode('''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
    await assertHasAssistAt('AAA [', '''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
  }

  Future<void> test_onText_hasFirstLine() async {
    await resolveTestCode('''
class A {
  /** AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
    await assertHasAssistAt('AAA [', '''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
  }

  Future<void> test_onText_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.slash_for_doc_comments]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_preserveIndentation() async {
    await resolveTestCode('''
class A {
  /**
   * First line.
   *     Indented line.
   * Last line.
   */
  m() {}
}
''');
    await assertHasAssistAt('Indented', '''
class A {
  /// First line.
  ///     Indented line.
  /// Last line.
  m() {}
}
''');
  }
}
