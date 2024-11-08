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
  Future<void> test_expected_onKeyword_multi() async {
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

  Future<void> test_expected_onKeyword() async {
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

  Future<void> test_expected_onKeyword_betweenNameAndType() async {
    await resolveTestCode('''
extension E int {}
''');
    await assertHasFix('''
extension E on int {}
''');
  }

  Future<void> test_expected_onKeyword_betweenTypeParameterAndType() async {
    await resolveTestCode('''
extension E<T> int {}
''');
    await assertHasFix('''
extension E<T> on int {}
''');
  }

  Future<void> test_expected_onKeyword_nonType() async {
    await resolveTestCode('''
extension UnresolvedType {}
''');
    await assertHasFix(
      '''
extension on UnresolvedType {}
''',
      errorFilter: (error) {
        return error.errorCode == ParserErrorCode.EXPECTED_TOKEN;
      },
    );
  }

  Future<void> test_expected_onKeyword_nonTypeWithTypeArguments() async {
    // We want to believe that the type parameter is from the undefined type.
    await resolveTestCode('''
extension UnresolvedType<T> {}
''');
    await assertHasFix(
      '''
extension on UnresolvedType<T> {}
''',
      errorFilter: (error) {
        return error.errorCode == ParserErrorCode.EXPECTED_TOKEN;
      },
    );
  }

  Future<void> test_expected_onKeyword_typeWithTypeArguments() async {
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
