// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class I1 {
  int interfaceMethod1() => 0;
  int get interfaceGetter1 => 0;
  set interfaceSetter1(int value) {}
}

abstract class I2 {
  int interfaceMethod2();
  int get interfaceGetter2;
  set interfaceSetter2(int value);
}

mixin M on Object {
  int mixedInMethod() => 42;
}

enum E with M implements I1, I2 {
  e1,
  e2,
  e3;

  @override
  int interfaceMethod1() => 42;
  @override
  int get interfaceGetter1 => 42;
  @override
  set interfaceSetter1(int value) {}
  @override
  int interfaceMethod2() => 42;
  @override
  int get interfaceGetter2 => 42;
  @override
  set interfaceSetter2(int value) {}

  static int staticMethod() => 42;
  static int get staticGetter => _staticField;
  static set staticSetter(int x) => _staticField = x;
  static int _staticField = 0;
}

enum F<T> {
  f1<int>(1),
  f2('foo'),
  f3(<String, dynamic>{});

  const F(this.value);

  void debugMethod() {
    debugger();
  }

  final T value;

  @override
  String toString() => 'OVERRIDE ${value.toString()}';
}

void testMain() {
  debugger();
  F.f1.debugMethod();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
