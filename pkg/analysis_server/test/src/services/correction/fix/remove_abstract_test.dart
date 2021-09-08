// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAbstractBulkTest);
    defineReflectiveTests(RemoveAbstractTest);
  });
}

@reflectiveTest
class RemoveAbstractBulkTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ABSTRACT_MULTI;

  Future<void> test_bulk() async {
    await resolveTestCode('''
class MyClass {
  abstract void m1() {}
  abstract void m2() {}
}
''');
    await assertHasFixAllFix(ParserErrorCode.ABSTRACT_CLASS_MEMBER, '''
class MyClass {
  void m1() {}
  void m2() {}
}
''');
  }
}

@reflectiveTest
class RemoveAbstractTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ABSTRACT;

  Future<void> test_extension() async {
    await resolveTestCode('''
extension E on String {
  abstract void m() {}
}
''');
    await assertHasFix('''
extension E on String {
  void m() {}
}
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin M {
  abstract void m() {}
}
''');
    await assertHasFix('''
mixin M {
  void m() {}
}
''');
  }

  Future<void> test_spaces() async {
    await resolveTestCode('''
abstract class MyClass {
  abstract    void m1();
}
''');
    await assertHasFix('''
abstract class MyClass {
  void m1();
}
''');
  }
}
