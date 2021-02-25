// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InsertSemicolonTest);
  });
}

@reflectiveTest
class InsertSemicolonTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.INSERT_SEMICOLON;

  Future<void> test_expectedToken_semicolon() async {
    await resolveTestCode('''
main() {
  print(0)
}
''');
    await assertHasFix('''
main() {
  print(0);
}
''');
  }
}
