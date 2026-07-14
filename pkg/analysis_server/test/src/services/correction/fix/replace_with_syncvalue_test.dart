// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithSyncValueBulkTest);
    defineReflectiveTests(ReplaceWithSyncValueLintTest);
  });
}

@reflectiveTest
class ReplaceWithSyncValueBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.future_sync_value;

  Future<void> test_instanceCreation() async {
    await resolveTestCode('''
Future<int> f() => Future.value(1);
Future<int> g() => .value(1);
''');
    await assertHasFix('''
Future<int> f() => Future.syncValue(1);
Future<int> g() => .syncValue(1);
''');
  }
}

@reflectiveTest
class ReplaceWithSyncValueLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithSyncValue;

  @override
  String get lintCode => LintNames.future_sync_value;

  Future<void> test_dotShorthands() async {
    await resolveTestCode('''
Future<int> f() => .value(1);
''');
    await assertHasFix('''
Future<int> f() => .syncValue(1);
''');
  }

  Future<void> test_instanceCreation() async {
    await resolveTestCode('''
Future<int> f() => Future.value(1);
''');
    await assertHasFix('''
Future<int> f() => Future.syncValue(1);
''');
  }
}
