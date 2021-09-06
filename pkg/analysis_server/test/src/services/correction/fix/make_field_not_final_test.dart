// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeFieldNotFinalTest);
  });
}

@reflectiveTest
class MakeFieldNotFinalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FIELD_NOT_FINAL;

  Future<void> test_hasType() async {
    await resolveTestCode('''
class A {
  final int fff = 1;
  main() {
    fff = 2;
  }
}
''');
    await assertHasFix('''
class A {
  int fff = 1;
  main() {
    fff = 2;
  }
}
''');
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
class A {
  final fff = 1;
  main() {
    fff = 2;
  }
}
''');
    await assertHasFix('''
class A {
  var fff = 1;
  main() {
    fff = 2;
  }
}
''');
  }
}
