// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithInterpolationTest);
  });
}

@reflectiveTest
class ReplaceWithInterpolationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_INTERPOLATION;

  @override
  String get lintCode => LintNames.prefer_interpolation_to_compose_strings;

  Future<void> test_stringLiteral_binaryExpression_stringConcatenation() async {
    await resolveTestCode('''
var b = ['b', 'c'];
var c = 'a' + b[0] + b[1];
''');
    await assertHasFix(r'''
var b = ['b', 'c'];
var c = 'a${b[0]}${b[1]}';
''');
  }

  Future<void> test_stringLiteral_expression_toString() async {
    await resolveTestCode('''
var b = [1];
var c = 'a' + b[0].toString();
''');
    await assertHasFix(r'''
var b = [1];
var c = 'a${b[0]}';
''');
  }

  Future<void> test_stringLiteral_indexExpression() async {
    await resolveTestCode('''
var b = ['b'];
var c = 'a' + b[0];
''');
    await assertHasFix(r'''
var b = ['b'];
var c = 'a${b[0]}';
''');
  }

  Future<void> test_stringLiteral_parenthesizedExpression() async {
    await resolveTestCode('''
var b = ['b'];
var c = 'a' + (b[0]);
''');
    await assertHasFix(r'''
var b = ['b'];
var c = 'a${b[0]}';
''');
  }

  Future<void> test_stringLiteral_parenthesizedExpression_toString() async {
    await resolveTestCode('''
var a = 1;
var b = 2;
var c = 'a' + (a + b).toString();
''');
    await assertHasFix(r'''
var a = 1;
var b = 2;
var c = 'a${a + b}';
''');
  }

  Future<void> test_stringLiteral_variable_notRaw_double_multi() async {
    await resolveTestCode('''
var b = 'b';
var c = """a""" + b;
''');
    await assertHasFix(r'''
var b = 'b';
var c = """a$b""";
''');
  }

  Future<void> test_stringLiteral_variable_notRaw_double_notMulti() async {
    await resolveTestCode('''
var b = 'b';
var c = "a" + b;
''');
    await assertHasFix(r'''
var b = 'b';
var c = "a$b";
''');
  }

  Future<void> test_stringLiteral_variable_notRaw_single_multi() async {
    await resolveTestCode("""
var b = 'b';
var c = '''a''' + b;
""");
    await assertHasFix(r"""
var b = 'b';
var c = '''a$b''';
""");
  }

  Future<void> test_stringLiteral_variable_notRaw_single_notMulti() async {
    await resolveTestCode('''
var b = 'b';
var c = 'a' + b;
''');
    await assertHasFix(r'''
var b = 'b';
var c = 'a$b';
''');
  }

  Future<void> test_stringLiteral_variable_raw_single_notMulti() async {
    await resolveTestCode('''
var b = 'b';
var c = r'a' + b;
''');
    await assertNoFix();
  }

  Future<void> test_stringLiteral_variable_withEscapes() async {
    await resolveTestCode(r'''
var b = 'b';
var c = '\$a' + b;
''');
    await assertHasFix(r'''
var b = 'b';
var c = '\$a$b';
''');
  }

  Future<void> test_variable_adjacentStrings() async {
    await resolveTestCode('''
var a = 'a';
var c = a + 'b' 'c';
''');
    await assertHasFix(r'''
var a = 'a';
var c = '${a}bc';
''');
  }

  Future<void> test_variable_stringLiteral_noRuntogther() async {
    await resolveTestCode('''
var a = 'a';
var c = a + ' b';
''');
    await assertHasFix(r'''
var a = 'a';
var c = '$a b';
''');
  }

  Future<void> test_variable_stringLiteral_runtogther() async {
    await resolveTestCode('''
var a = 'a';
var c = a + 'b';
''');
    await assertHasFix(r'''
var a = 'a';
var c = '${a}b';
''');
  }

  Future<void> test_variable_stringLiteral_variable() async {
    await resolveTestCode('''
var a = 'a';
var z = 'z';
var c = a + '...' + z;
''');
    await assertHasFix(r'''
var a = 'a';
var z = 'z';
var c = '$a...$z';
''');
  }
}
