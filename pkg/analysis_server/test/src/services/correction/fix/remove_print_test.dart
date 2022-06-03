// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemovePrintTest);
    defineReflectiveTests(RemovePrintMultiTest);
  });
}

@reflectiveTest
class RemovePrintMultiTest extends FixInFileProcessorTest {
  @override
  void setUp() {
    super.setUp();
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_print],
    );
  }

  Future<void> test_multi_prints() async {
    await resolveTestCode('''
void f() {
  print('');
  1+2;
  print('more');
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
void f() {
  1+2;
}
''');
  }

  Future<void> test_multi_prints_on_line() async {
    await resolveTestCode('''
void f() {
  print('');  3+4;  print('even more');
  1+2;
  print('more');
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
void f() {
  3+4;
  1+2;
}
''');
  }

  Future<void> test_multi_prints_stacked() async {
    await resolveTestCode('''
void f() {
  print('');
  print('more');
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
void f() {
}
''');
  }
}

@reflectiveTest
class RemovePrintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_PRINT;

  @override
  String get lintCode => LintNames.avoid_print;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig();
  }

  Future<void> test_multi_statement() async {
    await resolveTestCode('''
void f() {
  print(''); 1+2;
}
''');
    await assertHasFix('''
void f() {
  1+2;
}
''');
  }

  Future<void> test_multiline_but_still_simple() async {
    await resolveTestCode('''
void f() {
  print('asdfasdf'
    'sdfg'
       'sdfgsdfgsdfg'
           'sdfgsdfgsdfg'
       '${3}');
}
''');
    await assertHasFix('''
void f() {
}
''');
  }

  Future<void> test_nested() async {
    await resolveTestCode('''
void f(bool b) {
  b ? print('') : f(true);
}
''');
    await assertNoFix();
  }

  Future<void> test_statement() async {
    await resolveTestCode('''
void f() {
  print('');
}
''');
    await assertHasFix('''
void f() {
}
''');
  }
}
