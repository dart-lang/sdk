// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIsNotEmptyTest);
  });
}

@reflectiveTest
class UseIsNotEmptyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.USE_IS_NOT_EMPTY;

  @override
  String get lintCode => LintNames.prefer_is_not_empty;

  test_notIsEmpty() async {
    await resolveTestUnit('''
f(c) {
  if (/*LINT*/!c.isEmpty) {}
}
''');
    await assertHasFix('''
f(c) {
  if (/*LINT*/c.isNotEmpty) {}
}
''');
  }
}
