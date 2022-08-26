// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test tests the evaluation order in the case where a function
// invocation `m(a)` or `r.m(a)` involves the invocation of a getter `m`
// that returns a function object, and that function object is invoked
// with an actual argument `arg`.
//
// The expectation is that evaluation occurs left-to-right in every case,
// with one exception: when `m` is a class instance getter (this does not
// even apply to extension instance getters) the actual argument list is
// evaluated before the getter.

import 'package:expect/expect.dart';
import 'evaluation_order_lib.dart' as lib;

String effects = '';

void clearEffects() {
  effects = '';
}

void getterEffect() {
  effects += 'G';
}

void argumentEffect() {
  effects += 'A';
}

get arg => argumentEffect();

class A {
  void Function(void) get m {
    getterEffect();
    return (_) {};
  }

  static void Function(void) get n {
    getterEffect();
    return (_) {};
  }
}

class B extends A {
  void doTest() {
    test('Instance getter on explicit this', 'AG', () => this.m(arg));
    test('Instance getter on implicit this', 'GA', () => m(arg));
    test('Instance getter on super', 'GA', () => super.m(arg));
  }
}

mixin M on A {
  void doTest() {
    test('Instance getter on explicit this', 'AG', () => this.m(arg));
    test('Instance getter on implicit this', 'GA', () => m(arg));
    test('Instance getter on super', 'GA', () => super.m(arg));
  }
}

class AM = A with M;
class MockAM = MockA with M;

class MockA implements A {
  noSuchMethod(Invocation i) {
    getterEffect();
    return (_) {};
  }

  void Function(void) get m;
}

void Function(void) get m {
  getterEffect();
  return (_) {};
}

extension E on int {
  void Function(void) get m {
    getterEffect();
    return (_) {};
  }

  static void Function(void) get n {
    getterEffect();
    return (_) {};
  }
}

void test(String name, String expectation, void Function() code) {
  clearEffects();
  code();
  Expect.equals(expectation, effects, name);
}

main() {
  var a = A();
  dynamic d = a;
  A mockA = MockA();
  dynamic mockD = mockA;

  test('Instance getter on A', 'AG', () => a.m(arg));
  test('Instance getter on dynamic A', 'AG', () => d.m(arg));
  test('Instance getter on MockA', 'AG', () => mockA.m(arg));
  test('Instance getter on dynamic MockA', 'AG', () => mockD.m(arg));
  test('Static getter', 'GA', () => A.n(arg));
  test('Top-level getter', 'GA', () => m(arg));
  test('Prefix-imported getter', 'GA', () => lib.m(arg));
  test('Extension instance getter', 'GA', () => 1.m(arg));
  test('Extension static getter', 'GA', () => E.n(arg));
  B().doTest();
  AM().doTest();
  MockAM().doTest();
}
