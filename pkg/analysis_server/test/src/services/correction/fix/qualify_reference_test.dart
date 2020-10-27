// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(QualifyReferenceTest);
  });
}

@reflectiveTest
class QualifyReferenceTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.QUALIFY_REFERENCE;

  Future<void> test_class_direct() async {
    await resolveTestCode('''
class C {
  static void m() {}
}
class D extends C {
  void f() {
    m();
  }
}
''');
    await assertHasFix('''
class C {
  static void m() {}
}
class D extends C {
  void f() {
    C.m();
  }
}
''');
  }

  Future<void> test_class_imported() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    await resolveTestCode('''
import 'a.dart';
class B extends A {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_class_importedWithPrefix() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    await resolveTestCode('''
import 'a.dart' as a;
class B extends a.A {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_class_indirect() async {
    await resolveTestCode('''
class A {
  static void m() {}
}
class B extends A {}
class C extends B {}
class D extends C {
  void f() {
    m();
  }
}
''');
    await assertHasFix('''
class A {
  static void m() {}
}
class B extends A {}
class C extends B {}
class D extends C {
  void f() {
    A.m();
  }
}
''');
  }

  Future<void> test_class_notImported() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    newFile('/home/test/lib/b.dart', content: '''
import 'a.dart';
class B extends A {}
''');
    await resolveTestCode('''
import 'b.dart';
class C extends B {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_extension_direct() async {
    await resolveTestCode('''
class C {
  static void m() {}
}
extension E on C {
  void f() {
    m();
  }
}
''');
    await assertHasFix('''
class C {
  static void m() {}
}
extension E on C {
  void f() {
    C.m();
  }
}
''');
  }

  Future<void> test_extension_imported() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    await resolveTestCode('''
import 'a.dart';
extension E on A {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_extension_importedWithPrefix() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    await resolveTestCode('''
import 'a.dart' as a;
extension E on a.A {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_extension_indirect() async {
    await resolveTestCode('''
class A {
  static void m() {}
}
class B extends A {}
class C extends B {}
extension E on C {
  void f() {
    m();
  }
}
''');
    await assertHasFix('''
class A {
  static void m() {}
}
class B extends A {}
class C extends B {}
extension E on C {
  void f() {
    A.m();
  }
}
''');
  }

  Future<void> test_extension_notImported() async {
    newFile('/home/test/lib/a.dart', content: '''
class A {
  static void m() {}
}
''');
    newFile('/home/test/lib/b.dart', content: '''
import 'a.dart';
class B extends A {}
''');
    await resolveTestCode('''
import 'b.dart';
extension E on B {
  void f() {
    m();
  }
}
''');
    await assertNoFix();
  }
}
