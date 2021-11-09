// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSingleQuotedStringBulkTest);
    defineReflectiveTests(ConvertToSingleQuotedStringInFileTest);
    defineReflectiveTests(ConvertToSingleQuotedStringTest);
  });
}

@reflectiveTest
class ConvertToSingleQuotedStringBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_single_quotes;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  print("abc");
  print("e" + "f" + "g");
}
''');
    await assertHasFix('''
void f() {
  print('abc');
  print('e' + 'f' + 'g');
}
''');
  }
}

@reflectiveTest
class ConvertToSingleQuotedStringInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_single_quotes]);
    await resolveTestCode(r'''
void f() {
  print("abc");
  print("e" + "f" + "g");
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
void f() {
  print('abc');
  print('e' + 'f' + 'g');
}
''');
  }
}

@reflectiveTest
class ConvertToSingleQuotedStringTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  String get lintCode => LintNames.prefer_single_quotes;

  Future<void> test_one_interpolation() async {
    await resolveTestCode(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print("a $b-${c} d");
}
''');
    await assertHasFix(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print('a $b-${c} d');
}
''');
  }

  /// More coverage in the `convert_to_single_quoted_string_test.dart` assist test.
  Future<void> test_one_simple() async {
    await resolveTestCode('''
void f() {
  print("abc");
}
''');
    await assertHasFix('''
void f() {
  print('abc');
}
''');
  }
}
