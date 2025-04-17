// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix/fix_processor.dart';
import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoGetterFixTest);
    defineReflectiveTests(ConvertIntoGetterTest);
  });
}

@reflectiveTest
class ConvertIntoGetterFixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_GETTER;

  Future<void> test_extension_final() async {
    await resolveTestCode('''
extension E on int {
  final int a;
}
''');
    await assertHasFix(
      '''
extension E on int {
  int get a => null;
}
''',
      errorFilter:
          (error) =>
              error.errorCode ==
              CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD,
    );
  }

  Future<void> test_extension_late() async {
    await resolveTestCode('''
extension E on int {
  late int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_extension_late_final() async {
    await resolveTestCode('''
extension E on int {
  late final int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_extension_nonFinal_nonLate() async {
    await resolveTestCode('''
extension E on int {
  int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_extension_notSingleField() async {
    await resolveTestCode('''
extension E on int {
  final int foo = 1, bar = 2;
}
''');
    await assertNoFix(
      errorFilter: (error) => error.offset == testCode.indexOf('foo'),
    );
    await assertNoFix(
      errorFilter: (error) => error.offset == testCode.indexOf('bar'),
    );
  }

  Future<void> test_extensionType_final() async {
    await resolveTestCode('''
extension type A(int i) {
  final int a;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => null;
}
''');
  }

  Future<void> test_extensionType_late() async {
    await resolveTestCode('''
extension type A(int i) {
  late int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_extensionType_late_final() async {
    await resolveTestCode('''
extension type A(int i) {
  late final int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_extensionType_nonFinal_nonLate() async {
    await resolveTestCode('''
extension type A(int i) {
  int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_extensionType_notSingleField() async {
    await resolveTestCode('''
extension type A(int i) {
  final int foo = 1, bar = 2;
}
''');
    await assertNoFix(
      errorFilter: (error) => error.offset == testCode.indexOf('foo'),
    );
    await assertNoFix(
      errorFilter: (error) => error.offset == testCode.indexOf('bar'),
    );
  }
}

@reflectiveTest
class ConvertIntoGetterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_GETTER;

  Future<void> test_extension_static() async {
    await resolveTestCode('''
extension E on int {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
extension E on int {
  static int get a => 0;
}
''');
  }

  Future<void> test_extensionType_static() async {
    await resolveTestCode('''
extension type A(int i) {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
extension type A(int i) {
  static int get a => 0;
}
''');
  }

  Future<void> test_late() async {
    await resolveTestCode('''
class A {
  late final int ^f = 1 + 2;
}
''');
    await assertHasAssist('''
class A {
  int get f => 1 + 2;
}
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin M {
  final int ^v = 1;
}
''');
    await assertHasAssist('''
mixin M {
  int get v => 1;
}
''');
  }

  Future<void> test_mixin_static() async {
    await resolveTestCode('''
mixin M {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
mixin M {
  static int get a => 0;
}
''');
  }

  Future<void> test_noInitializer() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  final int ^foo;
}
''');
    await assertHasAssist('''
class A {
  int get foo => null;
}
''');
  }

  Future<void> test_notFinal() async {
    await resolveTestCode('''
class A {
  int ^foo = 1;
}
''');
    await assertHasAssist('''
class A {
  int get foo => 1;
}
''');
  }

  Future<void> test_notSingleField() async {
    await resolveTestCode('''
class A {
  final int ^foo = 1, bar = 2;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
class A {
  final ^foo = 42;
}
''');
    await assertHasAssist('''
class A {
  get foo => 42;
}
''');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
class A {
  static int ^foo = 1;
}
''');
    await assertHasAssist('''
class A {
  static int get foo => 1;
}
''');
  }

  Future<void> test_type() async {
    await resolveTestCode('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  final int ^foo = 1 + 2;
}
''');
    await assertHasAssist('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  int get foo => 1 + 2;
}
''');
  }
}
