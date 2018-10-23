// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeToStaticAccessTest);
  });
}

@reflectiveTest
class ChangeToStaticAccessTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  test_method() async {
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

  test_method_importType() async {
    addSource('/project/libA.dart', r'''
library libA;
class A {
  static foo() {}
}
''');
    addSource('/project/libB.dart', r'''
library libB;
import 'libA.dart';
class B extends A {}
''');
    await resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo();
}
''');
    await assertHasFix('''
import 'libA.dart';
import 'libB.dart';
main(B b) {
  A.foo();
}
''');
  }

  test_method_prefixLibrary() async {
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

  test_property() async {
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

  test_property_importType() async {
    addSource('/project/libA.dart', r'''
library libA;
class A {
  static get foo => null;
}
''');
    addSource('/project/libB.dart', r'''
library libB;
import 'libA.dart';
class B extends A {}
''');
    await resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo;
}
''');
    await assertHasFix('''
import 'libA.dart';
import 'libB.dart';
main(B b) {
  A.foo;
}
''');
  }
}
