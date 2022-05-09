// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToRawStringBulkTest);
    defineReflectiveTests(ConvertToRawStringTest);
  });
}

@reflectiveTest
class ConvertToRawStringBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_raw_strings;

  Future<void> test_bulk() async {
    await resolveTestCode(r"""
var a = 'text \\ \$ \\\\' "\\" '${'\\'}';
var b = '''
text \\ \$ \\\\
\\ \$ \\\\
''';
""");
    await assertHasFix(r"""
var a = r'text \ $ \\' r"\" '${r'\'}';
var b = r'''
text \ $ \\
\ $ \\
''';
""");
  }
}

@reflectiveTest
class ConvertToRawStringTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_RAW_STRING;

  @override
  String get lintCode => LintNames.use_raw_strings;

  Future<void> test_doubleQuotes() async {
    await resolveTestCode(r'var a = "text \\ \$ \\\\";');
    await assertHasFix(r'var a = r"text \ $ \\";');
  }

  Future<void> test_multiLines() async {
    await resolveTestCode(r"""
var a = '''
text \\ \$ \\\\
\\ \$ \\\\
''';
""");
    await assertHasFix(r"""
var a = r'''
text \ $ \\
\ $ \\
''';
""");
  }

  Future<void> test_singleQuotes() async {
    await resolveTestCode(r"var a = 'text \\ \$ \\\\';");
    await assertHasFix(r"var a = r'text \ $ \\';");
  }
}
