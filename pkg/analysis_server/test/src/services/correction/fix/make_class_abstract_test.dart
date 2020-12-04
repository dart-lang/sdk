// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeClassAbstractTest);
  });
}

@reflectiveTest
class MakeClassAbstractTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_CLASS_ABSTRACT;

  Future<void> test_declaresAbstractMethod() async {
    await resolveTestCode('''
class A {
  m();
}
''');
    await assertHasFix('''
abstract class A {
  m();
}
''');
  }

  Future<void> test_inheritsAbstractMethod() async {
    await resolveTestCode('''
abstract class A {
  m();
}
class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  m();
}
abstract class B extends A {
}
''');
  }
}
