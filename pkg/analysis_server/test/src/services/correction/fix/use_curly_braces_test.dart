// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(UseCurlyBracesTest);
    defineReflectiveTests(ControlBodyOnNewLineBulkTest);
    defineReflectiveTests(ControlBodyOnNewLineInFileTest);
    defineReflectiveTests(ControlBodyOnNewLineLintTest);
  });
}

@reflectiveTest
class ControlBodyOnNewLineBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_put_control_body_on_new_line;

  Future<void> test_bulk() async {
    await resolveTestCode('''
f() {
  while (true) print('');
}
f2() {
  while (true) print(2);
}
''');
    // This fix is only provided for explicit manual invocation for this lint,
    // not for bulk fixing.
    await assertNoFix();
  }
}

@reflectiveTest
class ControlBodyOnNewLineInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(
        lints: [LintNames.always_put_control_body_on_new_line]);
    await resolveTestCode(r'''
f() {
  while (true) print('');
}
f2() {
  while (true) print(2);
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
f() {
  while (true) {
    print('');
  }
}
f2() {
  while (true) {
    print(2);
  }
}
''');
  }
}

@reflectiveTest
class ControlBodyOnNewLineLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CURLY_BRACES;

  @override
  String get lintCode => LintNames.always_put_control_body_on_new_line;

  Future<void> test_field() async {
    await resolveTestCode('''
f() {
  while (true) print('');
}
''');
    await assertHasFix('''
f() {
  while (true) {
    print('');
  }
}
''');
  }
}

@reflectiveTest
class UseCurlyBracesTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.curly_braces_in_flow_control_structures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  while (true) if (false) print('');
}

f2() {
  while (true) print(2);
}
''');
    await assertHasFix('''
f() {
  while (true) if (false) {
    print('');
  }
}

f2() {
  while (true) {
    print(2);
  }
}
''');
  }
}
