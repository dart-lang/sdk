// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitMultipleDeclarationsBulkTest);
    defineReflectiveTests(SplitMultipleDeclarationsTest);
  });
}

@reflectiveTest
class SplitMultipleDeclarationsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_multiple_declarations_per_line;

  Future<void> test_Multiple() async {
    await resolveTestCode('''
var a = 'a', b = 'b';

const String? c = 'c',  d ='d',    e = 'e';

final r1 = ('a', 1), r2 , r3= ('b', 2);
''');
    await assertHasFix('''
var a = 'a';
var b = 'b';

const String? c = 'c';
const String? d ='d';
const String? e = 'e';

final r1 = ('a', 1);
final r2 ;
final r3= ('b', 2);
''');
  }
}

@reflectiveTest
class SplitMultipleDeclarationsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.SPLIT_MULTIPLE_DECLARATIONS;

  @override
  String get lintCode => LintNames.avoid_multiple_declarations_per_line;

  Future<void> test_const() async {
    await resolveTestCode('''
const a = 1, b = 2;
''');
    await assertHasFix('''
const a = 1;
const b = 2;
''');
  }

  Future<void> test_constTyped() async {
    await resolveTestCode('''
const String a = '', b = '';
''');
    await assertHasFix('''
const String a = '';
const String b = '';
''');
  }

  Future<void> test_indented() async {
    await resolveTestCode('''
  const String a = '', b = '';
''');
    await assertHasFix('''
  const String a = '';
  const String b = '';
''');
  }

  Future<void> test_late() async {
    await resolveTestCode('''
late String a = '', b = '';
''');
    await assertHasFix('''
late String a = '';
late String b = '';
''');
  }

  Future<void> test_lateFinal() async {
    await resolveTestCode('''
late final String a = '', b = '';
''');
    await assertHasFix('''
late final String a = '';
late final String b = '';
''');
  }

  Future<void> test_nullable() async {
    await resolveTestCode('''
int? x1, y1, z1;
''');
    await assertHasFix('''
int? x1;
int? y1;
int? z1;
''');
  }

  Future<void> test_varInitialized() async {
    await resolveTestCode('''
var a = 'a', b = 'b';
''');
    await assertHasFix('''
var a = 'a';
var b = 'b';
''');
  }

  Future<void> test_varNotInitialized() async {
    await resolveTestCode('''
var a, b;
''');
    await assertHasFix('''
var a;
var b;
''');
  }

  Future<void> test_varRecords() async {
    await resolveTestCode('''
var r1 = ('a', 1), r2 , r3= ('b', 2);
''');
    await assertHasFix('''
var r1 = ('a', 1);
var r2 ;
var r3= ('b', 2);
''');
  }

  Future<void> test_withCommentsBefore() async {
    await resolveTestCode('''
// multivariable comment
var a = 'a',  b = 'b', c = 'c';
''');
    await assertNoFix();
  }

  Future<void> test_withMetadata() async {
    await resolveTestCode('''
@override
var a = 'a',  b = 'b', c = 'c';
''');
    await assertNoFix();
  }
}
