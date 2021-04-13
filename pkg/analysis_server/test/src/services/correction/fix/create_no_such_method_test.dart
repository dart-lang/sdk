// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateNoSuchMethodTest);
  });
}

@reflectiveTest
class CreateNoSuchMethodTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_NO_SUCH_METHOD;

  Future<void> test_class() async {
    await resolveTestCode('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}
}
''');
    await assertHasFix('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_classTypeAlias() async {
    await resolveTestCode('''
abstract class A {
  m();
}

class B = Object with A;
''');
    await assertNoFix();
  }
}
