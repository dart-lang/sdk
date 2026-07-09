// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveInitializationToFieldDeclarationTest);
  });
}

@reflectiveTest
class MoveInitializationToFieldDeclarationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.moveInitializationToFieldDeclaration;

  @override
  String get lintCode => LintNames.initialize_in_field_declaration;

  Future<void> test_class_multipleFields() async {
    await resolveTestCode('''
class C(int x) {
  this : y = x, z = 0;

  int y, z;
}
''');
    await assertHasFix('''
class C(int x) {
  this : z = 0;

  int y = x, z;
}
''');
  }

  Future<void> test_class_multipleInitializers_first() async {
    await resolveTestCode('''
class C(int x) {
  this : y = x, z = 0;

  int y;
  int z;
}
''');
    await assertHasFix('''
class C(int x) {
  this : z = 0;

  int y = x;
  int z;
}
''');
  }

  Future<void> test_class_multipleInitializers_last() async {
    await resolveTestCode('''
class C(int x) {
  this : y = 0, z = x;

  int y;
  int z;
}
''');
    await assertHasFix('''
class C(int x) {
  this : y = 0;

  int y;
  int z = x;
}
''');
  }

  Future<void> test_class_singleInitializer() async {
    await resolveTestCode('''
class C(int x) {
  this : y = x;

  int y;
}
''');
    await assertHasFix('''
class C(int x) {
  this;

  int y = x;
}
''');
  }
}
