// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrapInFutureTest);
  });
}

@reflectiveTest
class WrapInFutureTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.WRAP_IN_FUTURE;

  @override
  String get lintCode => LintNames.avoid_returning_null_for_future;

  Future<void> test_asyncFor() async {
    await resolveTestCode('''
Future<String> f() {
  return null;
}
''');
    await assertHasFix('''
Future<String> f() {
  return Future.value(null);
}
''');
  }
}
