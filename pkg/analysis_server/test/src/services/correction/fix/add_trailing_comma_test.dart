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
    defineReflectiveTests(AddTrailingCommaBulkTest);
    defineReflectiveTests(AddTrailingCommaInFileTest);
    defineReflectiveTests(AddTrailingCommaTest);
  });
}

@reflectiveTest
class AddTrailingCommaBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.require_trailing_commas;

  Future<void> test_bulk() async {
    await resolveTestCode('''
Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    await assertHasFix('''
Object f(a, b) {
  f(f('a',
      'b',), 'b',);
  return a;
}
''');
  }
}

@reflectiveTest
class AddTrailingCommaInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.require_trailing_commas]);
    await resolveTestCode(r'''
Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
Object f(a, b) {
  f(f('a',
      'b',), 'b',);
  return a;
}
''');
  }
}

@reflectiveTest
class AddTrailingCommaTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_TRAILING_COMMA;

  @override
  String get lintCode => LintNames.require_trailing_commas;

  Future<void> test_named() async {
    await resolveTestCode('''
void f({a, b}) {
  f(a: 'a',
    b: 'b');
}
''');
    await assertHasFix('''
void f({a, b}) {
  f(a: 'a',
    b: 'b',);
}
''');
  }

  Future<void> test_positional() async {
    await resolveTestCode('''
void f(a, b) {
  f('a',
    'b');
}
''');
    await assertHasFix('''
void f(a, b) {
  f('a',
    'b',);
}
''');
  }
}
