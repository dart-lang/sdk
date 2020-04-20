// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstTest);
  });
}

@reflectiveTest
class RemoveConstTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_const_with_non_const() async {
    await resolveTestUnit('''
class A {
  A();
}
void f() {
  var a = const A();
  print(a);
}
''');
    await assertHasFix('''
class A {
  A();
}
void f() {
  var a = A();
  print(a);
}
''');
  }
}
