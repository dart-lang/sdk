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
    defineReflectiveTests(RemoveReturnedValueBulkTest);
    defineReflectiveTests(RemoveReturnedValueTest);
  });
}

@reflectiveTest
class RemoveReturnedValueBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_returning_null_for_void;

  Future<void> test_simple() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) {
    return null;
  } else {
    return null;
  }
}
''');
    await assertHasFix('''
void f(bool b) {
  if (b) {
    return;
  } else {
    return;
  }
}
''');
  }
}

@reflectiveTest
class RemoveReturnedValueTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_RETURNED_VALUE;

  @override
  String get lintCode => LintNames.avoid_returning_null_for_void;

  Future<void> test_simple() async {
    await resolveTestCode('''
void f() {
  return null;
}
''');
    await assertHasFix('''
void f() {
  return;
}
''');
  }
}
