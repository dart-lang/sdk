// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertDefaultToPrimaryConstructorTest);
  });
}

@reflectiveTest
class ConvertDefaultToPrimaryConstructorTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertDefaultToPrimaryConstructor;

  @override
  String get lintCode => LintNames.use_primary_constructors;

  Future<void> test_class() async {
    await resolveTestCode('''
class C^;
''');
    await assertHasFix('''
class C();
''');
  }

  Future<void> test_enum() async {
    await resolveTestCode('''
enum E^ {
  a, b;
}
''');
    await assertHasFix('''
enum E() {
  a, b;
}
''');
  }
}
