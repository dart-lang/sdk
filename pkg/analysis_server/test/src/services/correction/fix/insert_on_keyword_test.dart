// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InsertOnKeywordMultiTest);
    defineReflectiveTests(InsertOnKeywordTest);
  });
}

@reflectiveTest
class InsertOnKeywordMultiTest extends FixInFileProcessorTest {
  Future<void> test_hasName() async {
    await resolveTestCode('''
extension String {}
extension String {}
''');
    var fixes = await getFixesForFirst(
      (e) => e.errorCode == ParserErrorCode.EXPECTED_TOKEN,
    );
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
extension on String {}
extension on String {}
''');
  }
}

@reflectiveTest
class InsertOnKeywordTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.INSERT_ON_KEYWORD;

  Future<void> test_hasName() async {
    await resolveTestCode('''
extension int {}
''');
    await assertHasFix(
      '''
extension on int {}
''',
      errorFilter: (error) {
        return error.errorCode == ParserErrorCode.EXPECTED_TOKEN;
      },
    );
  }

  Future<void> test_hasName_hasType() async {
    await resolveTestCode('''
extension E int {}
''');
    await assertHasFix('''
extension E on int {}
''');
  }

  Future<void> test_hasName_hasType_withTypeArguments() async {
    await resolveTestCode('''
extension E List<int> {}
''');
    await assertHasFix('''
extension E on List<int> {}
''');
  }

  Future<void> test_hasName_hasTypeParameters_noType() async {
    await resolveTestCode('''
extension E<T> int {}
''');
    await assertHasFix('''
extension E<T> on int {}
''');
  }

  Future<void> test_noName_hasType_withTypeArguments() async {
    await resolveTestCode('''
extension List<int> {}
''');
    await assertHasFix(
      '''
extension on List<int> {}
''',
      errorFilter: (error) {
        return error.errorCode == ParserErrorCode.EXPECTED_TOKEN;
      },
    );
  }
}
