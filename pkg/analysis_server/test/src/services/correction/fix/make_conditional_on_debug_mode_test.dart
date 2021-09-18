// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeConditionalOnDebugModeTest);
    defineReflectiveTests(MakeConditionalOnDebugModeWithoutFlutterTest);
  });
}

@reflectiveTest
class MakeConditionalOnDebugModeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_CONDITIONAL_ON_DEBUG_MODE;

  @override
  String get lintCode => LintNames.avoid_print;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
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
  if (kDebugMode) {
    print('');
  }
}
''');
  }
}

@reflectiveTest
class MakeConditionalOnDebugModeWithoutFlutterTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_CONDITIONAL_ON_DEBUG_MODE;

  @override
  String get lintCode => LintNames.avoid_print;

  Future<void> test_statement() async {
    await resolveTestCode('''
void f() {
  print('');
}
''');
    await assertNoFix();
  }
}
