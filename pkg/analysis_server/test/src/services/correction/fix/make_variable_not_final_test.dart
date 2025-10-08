// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeVariableNotFinalTest);
  });
}

@reflectiveTest
class MakeVariableNotFinalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.makeVariableNotFinal;

  Future<void> test_hasType() async {
    await resolveTestCode('''
void f() {
  final int fff = 1;
  fff = 2;
  print(fff);
}
''');
    await assertHasFix('''
void f() {
  int fff = 1;
  fff = 2;
  print(fff);
}
''');
  }

  Future<void> test_lateFinalLocalAlreadyAssigned() async {
    await resolveTestCode('''
main() {
  late final int v;
  v = 0;
  v += 1;
  v;
}
''');
    await assertHasFix('''
main() {
  late int v;
  v = 0;
  v += 1;
  v;
}
''');
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
void f() {
  final fff = 1;
  fff = 2;
  print(fff);
}
''');
    await assertHasFix('''
void f() {
  var fff = 1;
  fff = 2;
  print(fff);
}
''');
  }
}
