// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedLabelTest);
  });
}

@reflectiveTest
class RemoveUnusedLabelTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_LABEL;

  Future<void> test_unused_onWhile() async {
    await resolveTestCode('''
f() {
  x:
  while (true) {
    break;
  }
}
''');
    await assertHasFix('''
f() {
  while (true) {
    break;
  }
}
''');
  }

  Future<void> test_unused_onWhile_sameLine() async {
    await resolveTestCode('''
f() {
  x: while (true) {
    break;
  }
}
''');
    await assertHasFix('''
f() {
  while (true) {
    break;
  }
}
''');
  }
}
