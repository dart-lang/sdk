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
    defineReflectiveTests(RemoveUnnecessaryToListBulkTest);
    defineReflectiveTests(RemoveUnnecessaryToListTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryToListBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_to_list_in_spreads;

  Future<void> test_in_file() async {
    await resolveTestCode(r'''
var t1 = [
  ...[1, 2].toList(),
  ...[3, 4].toList(),
];
''');
    await assertHasFix(r'''
var t1 = [
  ...[1, 2],
  ...[3, 4],
];
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryToListTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_TO_LIST;

  @override
  String get lintCode => LintNames.unnecessary_to_list_in_spreads;

  Future<void> test_list() async {
    await resolveTestCode(r'''
var t1 = [
  ...[1, 2].toList(),
];
''');
    await assertHasFix(r'''
var t1 = [
  ...[1, 2],
];
''');
  }
}
