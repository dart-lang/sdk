// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoBlockBodyTest);
  });
}

@reflectiveTest
class ConvertIntoBlockBodyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_BLOCK_BODY;

  Future<void> test_function() async {
    await resolveTestCode('''
void f();
''');
    await assertHasFix('''
void f() {
  // TODO: implement f
}
''');
  }

  Future<void> test_method_Never() async {
    await resolveTestCode('''
class A {
  Never m();
}
''');
    await assertHasFix('''
class A {
  Never m() {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_nonVoid() async {
    await resolveTestCode('''
class A {
  String m(int i);
}
''');
    await assertHasFix('''
class A {
  String m(int i) {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_void() async {
    await resolveTestCode('''
class A {
  void m();
}
''');
    await assertHasFix('''
class A {
  void m() {
    // TODO: implement m
  }
}
''');
  }
}
