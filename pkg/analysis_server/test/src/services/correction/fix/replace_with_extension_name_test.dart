// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithExtensionNameTest);
  });
}

@reflectiveTest
class ReplaceWithExtensionNameTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_EXTENSION_NAME;

  Future<void> test_getter() async {
    await resolveTestCode('''
extension E on String {
  static int get g => 0;
}

void f() {
  E('a').g;
}
''');
    await assertHasFix('''
extension E on String {
  static int get g => 0;
}

void f() {
  E.g;
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
extension E on String {
  static int m() => 0;
}

void f() {
  E('a').m();
}
''');
    await assertHasFix('''
extension E on String {
  static int m() => 0;
}

void f() {
  E.m();
}
''');
  }

  Future<void> test_qualified() async {
    newFile('/home/test/lib/ext.dart', content: '''
extension E on String {
  static int m() => 0;
}
''');
    await resolveTestCode('''
import 'ext.dart' as ext;

void f() {
  ext.E('a').m();
}
''');
    await assertHasFix('''
import 'ext.dart' as ext;

void f() {
  ext.E.m();
}
''');
  }

  Future<void> test_setter() async {
    await resolveTestCode('''
extension E on String {
  static set s(int i) {}
}

void f() {
  E('a').s = 3;
}
''');
    await assertHasFix('''
extension E on String {
  static set s(int i) {}
}

void f() {
  E.s = 3;
}
''');
  }
}
