// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertDocumentationIntoBlockTest);
  });
}

@reflectiveTest
class ConvertDocumentationIntoBlockTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK;

  test_alreadyBlock() async {
    await resolveTestUnit('''
/**
 * AAAAAAA
 */
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  test_noSpaceBeforeText() async {
    await resolveTestUnit('''
class A {
  /// AAAAA
  ///BBBBB
  ///
  /// CCCCC
  mmm() {}
}
''');
    await assertHasAssistAt('AAAAA', '''
class A {
  /**
   * AAAAA
   *BBBBB
   *
   * CCCCC
   */
  mmm() {}
}
''');
  }

  test_notDocumentation() async {
    await resolveTestUnit('''
// AAAA
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  test_onReference() async {
    await resolveTestUnit('''
/// AAAAAAA [int] AAAAAAA
class A {}
''');
    await assertHasAssistAt('nt]', '''
/**
 * AAAAAAA [int] AAAAAAA
 */
class A {}
''');
  }

  test_onText() async {
    await resolveTestUnit('''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
    await assertHasAssistAt('AAA [', '''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
  }
}
