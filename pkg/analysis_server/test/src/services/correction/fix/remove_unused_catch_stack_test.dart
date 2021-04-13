// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedCatchStackTest);
  });
}

@reflectiveTest
class RemoveUnusedCatchStackTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_CATCH_STACK;

  Future<void> test_removeUnusedCatchStack() async {
    await resolveTestCode('''
main() {
  try {
    throw 42;
  } catch (e, stack) {
  }
}
''');
    await assertHasFix('''
main() {
  try {
    throw 42;
  } catch (e) {
  }
}
''');
  }
}
