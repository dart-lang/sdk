// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveInvocationBulkTest);
    defineReflectiveTests(RemoveInvocationTest);
  });
}

@reflectiveTest
class RemoveInvocationBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.noop_primitive_operations;

  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
var s = '${1.toString()}${2.toString()}';
''');
    await assertHasFix(r'''
var s = '${1}${2}';
''');
  }
}

@reflectiveTest
class RemoveInvocationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_INVOCATION;

  @override
  String get lintCode => LintNames.noop_primitive_operations;

  Future<void> test_intLiteral() async {
    await resolveTestCode(r'''
var s = '${1.toString()}';
''');
    await assertHasFix(r'''
var s = '${1}';
''');
  }
}
