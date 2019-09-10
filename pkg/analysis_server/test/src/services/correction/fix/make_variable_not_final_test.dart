// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeVariableNotFinalTest);
  });
}

@reflectiveTest
class MakeVariableNotFinalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_VARIABLE_NOT_FINAL;

  test_hasType() async {
    await resolveTestUnit('''
main() {
  final int fff = 1;
  fff = 2;
  print(fff);
}
''');
    await assertHasFix('''
main() {
  int fff = 1;
  fff = 2;
  print(fff);
}
''');
  }

  test_noType() async {
    await resolveTestUnit('''
main() {
  final fff = 1;
  fff = 2;
  print(fff);
}
''');
    await assertHasFix('''
main() {
  var fff = 1;
  fff = 2;
  print(fff);
}
''');
  }
}
