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
    defineReflectiveTests(InlineInvocationBulkTest);
    defineReflectiveTests(InlineInvocationTest);
  });
}

@reflectiveTest
class InlineInvocationBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_inlined_adds;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
var l = []..add('a')..add('b');
var l2 = ['a', 'b']..add('c');
var l3 = ['a']..addAll(['b', 'c']);
''');
    await assertHasFix('''
var l = ['a']..add('b');
var l2 = ['a', 'b', 'c'];
var l3 = ['a', 'b', 'c'];
''');
  }
}

@reflectiveTest
class InlineInvocationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.INLINE_INVOCATION;

  @override
  String get lintCode => LintNames.prefer_inlined_adds;

  /// More coverage in the `inline_invocation_test.dart` assist test.
  Future<void> test_add_emptyTarget() async {
    await resolveTestCode('''
var l = []..add('a')..add('b');
''');
    await assertHasFix('''
var l = ['a']..add('b');
''');
  }
}
