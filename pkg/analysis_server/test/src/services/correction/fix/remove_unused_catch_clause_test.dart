// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedCatchClauseTest);
  });
}

@reflectiveTest
class RemoveUnusedCatchClauseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE;

  Future<void> test_removeUnusedCatchClause() async {
    await resolveTestCode('''
main() {
  try {
    throw 42;
  } on int catch (e) {
  }
}
''');
    await assertHasFix('''
main() {
  try {
    throw 42;
  } on int {
  }
}
''');
  }
}
