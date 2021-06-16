// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertDocumentationIntoBlockTest);
  });
}

@reflectiveTest
class ConvertDocumentationIntoBlockTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK;

  Future<void> test_alreadyBlock() async {
    await resolveTestCode('''
/**
 * AAAAAAA
 */
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  Future<void> test_noSpaceBeforeText() async {
    await resolveTestCode('''
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

  Future<void> test_notDocumentation() async {
    await resolveTestCode('''
// AAAA
class A {}
''');
    await assertNoAssistAt('AAA');
  }

  Future<void> test_onReference() async {
    await resolveTestCode('''
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

  Future<void> test_onText() async {
    await resolveTestCode('''
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
