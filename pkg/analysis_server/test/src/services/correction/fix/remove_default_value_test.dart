// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDefaultValueTest);
  });
}

@reflectiveTest
class RemoveDefaultValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeDefaultValue;

  Future<void> test_default_value_on_required_parameter() async {
    await resolveTestCode('''
class A {
  int i;
  A({required this.i = 1});
}
''');
    await assertHasFix('''
class A {
  int i;
  A({required this.i});
}
''');
  }

  Future<void> test_primaryConstructor_declaring() async {
    await resolveTestCode('''
class A({required final int i = 1});
''');
    await assertHasFix('''
class A({required final int i});
''');
  }

  Future<void> test_primaryConstructor_initializing() async {
    await resolveTestCode('''
class A({required this.i = 1}) {
  int i;
}
''');
    await assertHasFix('''
class A({required this.i}) {
  int i;
}
''');
  }

  Future<void> test_primaryConstructor_required() async {
    await resolveTestCode('''
class A({required int i = 1});
''');
    await assertHasFix('''
class A({required int i});
''');
  }

  Future<void> test_primaryConstructor_super() async {
    await resolveTestCode('''
class B {
  B({required int i});
}
class A({required super.i = 1}) extends B;
''');
    await assertHasFix('''
class B {
  B({required int i});
}
class A({required super.i}) extends B;
''');
  }
}
