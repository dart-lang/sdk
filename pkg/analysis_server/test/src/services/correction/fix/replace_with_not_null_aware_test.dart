// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithNotNullAwareBulkTest);
    defineReflectiveTests(ReplaceWithNotNullAwareTest);
  });
}

@reflectiveTest
class ReplaceWithNotNullAwareBulkTest extends BulkFixProcessorTest {
  Future<void> test_notShortCircuit() async {
    await resolveTestCode('''
void f(A a) {
  a?.b?.c;
}
class A {
  A get b => this;
  A get c => this;
}
''');
    await assertHasFix('''
void f(A a) {
  a.b.c;
}
class A {
  A get b => this;
  A get c => this;
}
''');
  }

  Future<void> test_shortCircuit() async {
    await resolveTestCode('''
void f(A? a) {
  a?.b?.c?.d;
}
class A {
  A get b => this;
  A get c => this;
  A get d => this;
}
''');
    await assertHasFix('''
void f(A? a) {
  a?.b.c.d;
}
class A {
  A get b => this;
  A get c => this;
  A get d => this;
}
''');
  }
}

@reflectiveTest
class ReplaceWithNotNullAwareTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_NOT_NULL_AWARE;

  Future<void> test_getter_cascade() async {
    await resolveTestCode('''
void f(String s) {
  s?..length;
}
''');
    await assertHasFix('''
void f(String s) {
  s..length;
}
''');
  }

  Future<void> test_getter_simple() async {
    await resolveTestCode('''
void f(String s) {
  s?.length;
}
''');
    await assertHasFix('''
void f(String s) {
  s.length;
}
''');
  }

  Future<void> test_index_cascade() async {
    await resolveTestCode('''
void f(List<int> x) {
  x?..[0];
}
''');
    await assertHasFix('''
void f(List<int> x) {
  x..[0];
}
''');
  }

  Future<void> test_index_simple() async {
    await resolveTestCode('''
void f(List<int> x) {
  x?[0];
}
''');
    await assertHasFix('''
void f(List<int> x) {
  x[0];
}
''');
  }

  Future<void> test_method_cascade() async {
    await resolveTestCode('''
void f(String s) {
  s?..indexOf('a');
}
''');
    await assertHasFix('''
void f(String s) {
  s..indexOf('a');
}
''');
  }

  Future<void> test_method_simple() async {
    await resolveTestCode('''
void f(String s) {
  s?.indexOf('a');
}
''');
    await assertHasFix('''
void f(String s) {
  s.indexOf('a');
}
''');
  }

  Future<void> test_setter_cascade() async {
    await resolveTestCode('''
void f(C c) {
  c?..s = 0;
}
class C {
  set s(int x) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c..s = 0;
}
class C {
  set s(int x) {}
}
''');
  }

  Future<void> test_setter_simple() async {
    await resolveTestCode('''
void f(C c) {
  c?.s = 0;
}
class C {
  set s(int x) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c.s = 0;
}
class C {
  set s(int x) {}
}
''');
  }

  Future<void> test_shortCircuit() async {
    await resolveTestCode('''
class C {
  C a(C? c) => c?.b?.b ?? this;
  C get b => this;
}
''');

    await assertHasFix('''
class C {
  C a(C? c) => c?.b.b ?? this;
  C get b => this;
}
''');
  }

  Future<void> test_spread() async {
    await resolveTestCode('''
void f(List<int> x) {
  [...?x];
}
''');
    await assertHasFix('''
void f(List<int> x) {
  [...x];
}
''');
  }
}
