// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineInvocationTest);
  });
}

@reflectiveTest
class InlineInvocationTest extends BulkFixProcessorTest {
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
