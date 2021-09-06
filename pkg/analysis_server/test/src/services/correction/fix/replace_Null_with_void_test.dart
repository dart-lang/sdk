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
    defineReflectiveTests(ReplaceNullWithVoidTest);
    defineReflectiveTests(ReplaceNullWithVoidBulkTest);
  });
}

@reflectiveTest
class ReplaceNullWithVoidBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_void_to_null;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
Future<Null> f() async {
  await Future.value();
}

Future<Null>? future_null;
''');
    await assertHasFix('''
Future<void> f() async {
  await Future.value();
}

Future<void>? future_null;
''');
  }
}

@reflectiveTest
class ReplaceNullWithVoidTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_NULL_WITH_VOID;

  @override
  String get lintCode => LintNames.prefer_void_to_null;

  Future<void> test_simple() async {
    await resolveTestCode('''
Future<Null> f() async {
  await Future.value();
}
''');
    await assertHasFix('''
Future<void> f() async {
  await Future.value();
}
''');
  }
}
