// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeToStaticAccessClassTest);
    defineReflectiveTests(ChangeToStaticAccessExtensionTest);
  });
}

@reflectiveTest
class ChangeToStaticAccessClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  Future<void> test_method() async {
    await resolveTestUnit('''
class A {
  static foo() {}
}
main(A a) {
  a.foo();
}
''');
    await assertHasFix('''
class A {
  static foo() {}
}
main(A a) {
  A.foo();
}
''');
  }

  Future<void> test_method_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {
  static foo() {}
}
''');
    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

class B extends A {}
''');
    await resolveTestUnit('''
import 'package:test/b.dart';

main(B b) {
  b.foo();
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

main(B b) {
  A.foo();
}
''');
  }

  Future<void> test_method_prefixLibrary() async {
    await resolveTestUnit('''
import 'dart:async' as pref;
main(pref.Future f) {
  f.wait([]);
}
''');
    await assertHasFix('''
import 'dart:async' as pref;
main(pref.Future f) {
  pref.Future.wait([]);
}
''');
  }

  Future<void> test_property() async {
    await resolveTestUnit('''
class A {
  static get foo => 42;
}
main(A a) {
  a.foo;
}
''');
    await assertHasFix('''
class A {
  static get foo => 42;
}
main(A a) {
  A.foo;
}
''');
  }

  Future<void> test_property_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {
  static get foo => null;
}
''');
    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

class B extends A {}
''');
    await resolveTestUnit('''
import 'package:test/b.dart';

main(B b) {
  b.foo;
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

main(B b) {
  A.foo;
}
''');
  }
}

@reflectiveTest
class ChangeToStaticAccessExtensionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  Future<void> test_method() async {
    createAnalysisOptionsFile(experiments: ['extension-methods']);
    await resolveTestUnit('''
extension E on int {
  static void foo() {}
}
main() {
  0.foo();
}
''');
    await assertHasFix('''
extension E on int {
  static void foo() {}
}
main() {
  E.foo();
}
''');
  }

  @failingTest
  Future<void> test_property() async {
    createAnalysisOptionsFile(experiments: ['extension-methods']);
    await resolveTestUnit('''
extension E on int {
  static int get foo => 42;
}
main() {
  0.foo;
}
''');
    await assertHasFix('''
extension E on int {
  static int get foo => 42;
}
main() {
  E.foo;
}
''');
  }
}
