// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberTest1);
    defineReflectiveTests(ClassMemberTest2);
    defineReflectiveTests(StaticClassMemberTest1);
    defineReflectiveTests(StaticClassMemberTest2);
  });
}

@reflectiveTest
class ClassMemberTest1 extends AbstractCompletionDriverTest
    with ClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassMemberTest2 extends AbstractCompletionDriverTest
    with ClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ClassMemberTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_inheritedFromPrivateClass() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class _W {
  M y0 = M();
  var _z0;
  m() {
    _z0;
  }
}
class X extends _W {}
class M {}
''');
    await computeSuggestions('''
import "b.dart";
foo(X x) {
  x.^
}
''');
    assertResponse(r'''
suggestions
  y0
    kind: field
''');
  }
}

@reflectiveTest
class StaticClassMemberTest1 extends AbstractCompletionDriverTest
    with StaticClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class StaticClassMemberTest2 extends AbstractCompletionDriverTest
    with StaticClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin StaticClassMemberTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCascade_onlyStatic_notFromSuperclass() async {
    await computeSuggestions('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void f() {C..^}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_afterCascade_onlyStatic_notFromSuperclass_async_partial() async {
    allowedIdentifiers = {'wait'};
    await computeSuggestions('''
import "dart:async" as async;
void f() {
  async.Future..w^()
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterCascade_onlyStatic_notFromSuperclass_partial() async {
    await computeSuggestions('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void f() {C..m^()}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void>
      test_afterPeriod_beforeStatement_onlyStatic_notFromSuperclass() async {
    // TODO(brianwilkerson) Split into two tests and remove extraneous code.
    await computeSuggestions('''
class B {
  static int b0;
}
class C extends B {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {C.^ print("something");}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_afterPeriod_onlyStatic_notFromSuperclass() async {
    // TODO(brianwilkerson) Split into two tests and remove extraneous code.
    await computeSuggestions('''
class B {
  static int b0;
}
class C extends B {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {C.^}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_afterPeriod_onlyStatic_notFromSuperclass_2() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class I {
  static const s2 = '';
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class B implements I {
  static const int s1 = 12;
  var b0;
  X0 _c0 = new X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  set s3(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) => this;
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class X0{}
void f(I i, B b) {
  i._g0;
  b._c0;
  b._e0;
  b._n0(new X0());
  b._s0 = i;
}
''');
    await computeSuggestions('''
import "b.dart";
class A0 extends B {
  static const String s0 = '';
  w0() {}
}
void f0() {
  A0.^
}
''');
    assertResponse(r'''
suggestions
  s0
    kind: field
''');
  }

  Future<void> test_afterPeriod_partial() async {
    await computeSuggestions('''
class C {
  static C get i0 => null;
}
void f() {
  C.i0^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  i0
    kind: getter
''');
  }

  Future<void> test_afterPeriod_private() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static int _f0 = 0;
  static String get _g0 => '';
  static int _m0() => 0;
  static set _s0(v) {}
  A._();
}
void f() {
  A._f0;
  A._g0;
  A._m0();
  A._s0 = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
void f() {
  A.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterPeriod_throughTypedef() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static int _p0 = 0;
  static int get _p1 => 0;
  static void _p2() {}
  static set _p3(int _) {}
  A._privateConstructor();

  static int p0 = 0;
  static int get p1 => 0;
  static void p2() {}
  static set p3(int _) {}
  A.p4();
}
void f() {
  A._p0;
  A._p1;
  A._p2();
  A._p3 = 0;
  A._privateConstructor();
}
''');
    await computeSuggestions('''
import 'a.dart';

typedef B = A;

void f() {
  B.^;
}
''');
    assertResponse(r'''
suggestions
  p0
    kind: field
  p1
    kind: getter
  p2
    kind: methodInvocation
  p3
    kind: setter
  p4
    kind: constructorInvocation
''');
  }

  Future<void> test_betweenPeriods_onlyStatic_notFromSuperclass() async {
    await computeSuggestions('''
class B {
  static int b0;
}
class C extends B {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {C.^.}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void>
      test_betweenPeriods_onlyStatic_notFromSuperclass_async_partial() async {
    allowedIdentifiers = {'wait'};
    await computeSuggestions('''
import "dart:async" as async;
void f() {async.Future.^.w()}
''');
    assertResponse(r'''
suggestions
  wait
    kind: methodInvocation
''');
  }

  Future<void>
      test_betweenPeriods_onlyStatic_notFromSuperclass_partial() async {
    await computeSuggestions('''
class B {
  static int b0;
}
class C extends B {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {C.^.m()}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_expression_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  // ignore: unused_field
  static const int _s1 = 1;
}
''');
    await computeSuggestions('''
import 'a.dart';
int f() {
  print(_s^
}
''');
    assertNoSuggestion(completion: 'A._s1');
  }

  Future<void> test_expression_private_sameLibrary_otherFile() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
class A {
  // ignore: unused_field
  static const int _s1 = 1;
}
''');
    await computeSuggestions('''
part 'a.dart';
int f() {
  print(_s^
}
''');
    assertSuggestion(completion: 'A._s1');
  }

  Future<void> test_expression_private_sameLibrary_sameFile() async {
    await computeSuggestions('''
class A {
  // ignore: unused_field
  static const int _s1 = 1;
}

int f() {
  print(_s^
}
''');
    assertSuggestion(completion: 'A._s1');
  }
}
