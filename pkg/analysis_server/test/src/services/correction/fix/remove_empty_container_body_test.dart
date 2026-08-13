// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyContainerBodyBulkTest);
    defineReflectiveTests(RemoveEmptyContainerBodyTest);
  });
}

@reflectiveTest
class RemoveEmptyContainerBodyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.empty_container_bodies;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {}

mixin M {}
''');
    await assertHasFix('''
class C;

mixin M;
''');
  }
}

@reflectiveTest
class RemoveEmptyContainerBodyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeEmptyContainerBody;

  @override
  String get lintCode => LintNames.empty_container_bodies;

  Future<void> test_class_multipleLines() async {
    await resolveTestCode('''
class C {
}
''');
    await assertHasFix('''
class C;
''');
  }

  Future<void> test_class_singleLine() async {
    await resolveTestCode('''
class C {}
''');
    await assertHasFix('''
class C;
''');
  }

  Future<void> test_class_withExtends() async {
    await resolveTestCode('''
class C extends Object {}
''');
    await assertHasFix('''
class C extends Object;
''');
  }

  Future<void> test_extension() async {
    await resolveTestCode('''
extension E on String {}
''');
    await assertHasFix('''
extension E on String;
''');
  }

  Future<void> test_extensionType() async {
    await resolveTestCode('''
extension type E(int i) {}
''');
    await assertHasFix('''
extension type E(int i);
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin M {}
''');
    await assertHasFix('''
mixin M;
''');
  }
}
