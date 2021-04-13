// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveOperatorTest);
  });
}

@reflectiveTest
class RemoveOperatorTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_OPERATOR;

  @override
  String get lintCode => LintNames.prefer_adjacent_string_concatenation;

  Future<void> test_plus() async {
    await resolveTestCode('''
var s = 'a' + 'b';
''');
    await assertHasFix('''
var s = 'a' 'b';
''');
  }
}
