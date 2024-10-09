// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseDivisionTest);
    defineReflectiveTests(UseEffectiveIntegerDivisionTest);
  });
}

@reflectiveTest
class UseDivisionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.USE_DIVISION;

  Future<void> test_class() async {
    await resolveTestCode('''
class A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
    await assertHasFix('''
class A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
  }

  Future<void> test_extension() async {
    await resolveTestCode('''
extension E on String {
  void operator /(dynamic _) {}
}

void f(String a) {
  a ~/ 0;
}
''');
    await assertHasFix('''
extension E on String {
  void operator /(dynamic _) {}
}

void f(String a) {
  a / 0;
}
''');
  }

  Future<void> test_extensionType() async {
    await resolveTestCode('''
extension type A(int i) {
  void operator /(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  void operator /(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
  }

  Future<void> test_external_extension() async {
    newFile('/home/test/lib/other.dart', '''
extension E on String {
  void operator /(dynamic _) {}
}
''');
    await resolveTestCode('''
void f(String a) {
  a ~/ 0;
}
''');
    await assertHasFix('''
void f(String a) {
  a / 0;
}
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
    await assertHasFix('''
mixin A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
  }

  Future<void> test_noOperator() async {
    await resolveTestCode('''
class A {}

void f(A a) {
  a ~/ 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_slashEq() async {
    await resolveTestCode('''
class A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a ~/= 0;
}
''');
    await assertHasFix('''
class A {
  void operator /(dynamic _) {}
}

void f(A a) {
  a /= 0;
}
''');
  }

  Future<void> test_subclass() async {
    await resolveTestCode('''
class A {
  void operator /(dynamic _) {}
}

class B extends A {}

void f(B b) {
  b ~/ 0;
}
''');
    await assertHasFix('''
class A {
  void operator /(dynamic _) {}
}

class B extends A {}

void f(B b) {
  b / 0;
}
''');
  }

  Future<void> test_typeVariable() async {
    await resolveTestCode('''
class A {
  void operator /(dynamic _) {}
}

void f<T extends A>(T t) {
  t ~/ 0;
}
''');
    await assertHasFix('''
class A {
  void operator /(dynamic _) {}
}

void f<T extends A>(T t) {
  t / 0;
}
''');
  }
}

@reflectiveTest
class UseEffectiveIntegerDivisionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION;

  Future<void> test_class() async {
    await resolveTestCode('''
class A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
    await assertHasFix('''
class A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
  }

  Future<void> test_extensionType() async {
    await resolveTestCode('''
extension type A(int i) {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a / 0;
}
''');
    await assertHasFix('''
mixin A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a ~/ 0;
}
''');
  }

  Future<void> test_noOperator() async {
    await resolveTestCode('''
class A {}

void f(A a) {
  a ~/ 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_subclass() async {
    await resolveTestCode('''
class A {
  void operator ~/(dynamic _) {}
}

class B extends A {}

void f(B b) {
  b / 0;
}
''');
    await assertHasFix('''
class A {
  void operator ~/(dynamic _) {}
}

class B extends A {}

void f(B b) {
  b ~/ 0;
}
''');
  }

  Future<void> test_tildeSlashEq() async {
    await resolveTestCode('''
class A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a /= 0;
}
''');
    await assertHasFix('''
class A {
  void operator ~/(dynamic _) {}
}

void f(A a) {
  a ~/= 0;
}
''');
  }

  Future<void> test_typeVariable() async {
    await resolveTestCode('''
class A {
  void operator ~/(dynamic _) {}
}

void f<T extends A>(T t) {
  t / 0;
}
''');
    await assertHasFix('''
class A {
  void operator ~/(dynamic _) {}
}

void f<T extends A>(T t) {
  t ~/ 0;
}
''');
  }
}
