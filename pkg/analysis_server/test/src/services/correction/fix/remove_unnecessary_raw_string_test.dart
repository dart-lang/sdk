// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(RemoveUnnecessaryRawStringBulkTest);
    defineReflectiveTests(RemoveUnnecessaryRawStringInFileTest);
    defineReflectiveTests(RemoveUnnecessaryRawStringTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryRawStringBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_raw_strings;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
var a = r'ace';
var b = r'aid';
''');
    await assertHasFix('''
var a = 'ace';
var b = 'aid';
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryRawStringInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    createAnalysisOptionsFile(lints: [LintNames.unnecessary_raw_strings]);
    await resolveTestCode('''
var a = r'ace';
var b = r'aid';
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
var a = 'ace';
var b = 'aid';
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryRawStringTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_RAW_STRING;

  @override
  String get lintCode => LintNames.unnecessary_raw_strings;

  Future<void> test_double() async {
    await resolveTestCode('''
var a = r"ace";
''');
    await assertHasFix('''
var a = "ace";
''');
  }

  Future<void> test_multi_line_double() async {
    await resolveTestCode('''
var a = r"""
abc
""";
''');
    await assertHasFix('''
var a = """
abc
""";
''');
  }

  Future<void> test_multi_line_single() async {
    await resolveTestCode("""
var a = r'''
abc
''';
""");
    await assertHasFix("""
var a = '''
abc
''';
""");
  }

  Future<void> test_single() async {
    await resolveTestCode('''
var a = r'ace';
''');
    await assertHasFix('''
var a = 'ace';
''');
  }
}
