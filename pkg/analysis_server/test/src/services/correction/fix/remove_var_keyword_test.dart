// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveVarKeywordTest);
  });
}

@reflectiveTest
class RemoveVarKeywordTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_VAR_KEYWORD;

  Future<void> test_declaredVariablePattern_patternAssignment() async {
    await resolveTestCode('''
f() {
  var a = 1;
  var b = 2;
  //ignore: unused_local_variable
  (var a, b) = (3, 4);
  print((a, b));
}
''');
    await assertHasFix('''
f() {
  var a = 1;
  var b = 2;
  //ignore: unused_local_variable
  (a, b) = (3, 4);
  print((a, b));
}
''');
  }
}
