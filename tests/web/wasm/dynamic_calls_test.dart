// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '' deferred as D;

void main() async {
  await D.loadLibrary();

  final list = D.getObjects();
  final a = list[int.parse('0')];
  final b = list[int.parse('1')];
  final c = list[int.parse('2')];
  final d = list[int.parse('3')];

  // Successfull dynamic method/getter/setter call
  Expect.equals(52, a.foo(10));
  Expect.equals(42, a.fooGetter);
  a.fooSetter = 100;
  Expect.equals(100, a.fooGetter);

  // Successfull dynamic tearoff + dynamic closure call.
  final fooTearOff = a.foo;
  Expect.equals(110, fooTearOff(10));

  // Successful call via field.
  Expect.equals(20, b.foo(10));

  // Argument type check errors
  Expect.throws<TypeError>(() => a.foo(''));
  Expect.throws<TypeError>(() => a.fooSetter = '');

  // User-defined noSuchMethod handler
  Expect.equals(1, c.foo(1));
  Expect.equals(2, c.bar(1, 2));
  Expect.equals(3, c.baz);
  c.buz = 2;
  Expect.equals(4, D.cCounter);

  // Default noSuchMethod handler
  Expect.throwsNoSuchMethodError(() => d.foo(10));
  Expect.throwsNoSuchMethodError(() => d.fooGetter);
  Expect.throwsNoSuchMethodError(() => d.fooSetter = 10);

  final e = list[int.parse('4')];

  // Optional positional and type args
  Expect.equals("$Object 10 1 2", e.foo(10));
  Expect.equals("$Object 10 20 2", e.foo(10, 20));
  Expect.equals("$Object 10 20 30", e.foo(10, 20, 30));
  Expect.equals("$String hi 1 2", e.foo<String>("hi"));
  Expect.equals("$String hi 20 30", e.foo<String>("hi", 20, 30));

  // Optional named and type args
  Expect.equals("$Object $dynamic 10 null 3", e.bar(10));
  Expect.equals("$int $String 10 hi 3", e.bar<int, String>(10, y: "hi"));
  Expect.equals(
    "$int $String 10 hi 40",
    e.bar<int, String>(10, y: "hi", z: 40),
  );
  Expect.equals("$Object $dynamic 10 null 40", e.bar(10, z: 40));

  // NoSuchMethod for wrong shape
  Expect.throwsNoSuchMethodError(() => e.foo());
  Expect.throwsNoSuchMethodError(() => e.foo(1, 2, 3, 4));
  Expect.throwsNoSuchMethodError(() => e.bar(10, unknown: 1));
}

List<dynamic> getObjects() => <dynamic>[
  A(),
  B((int x) => x * 2),
  C(),
  Object(),
  OptionalArgs(),
];

class A {
  int _value = 42;

  int foo(int x) => x + _value;
  int get fooGetter => _value;
  set fooSetter(int x) => _value = x;
}

class B {
  final Function foo;
  B(this.foo);
}

int cCounter = 0;

class C {
  @override
  noSuchMethod(Invocation i) => ++cCounter;
}

class OptionalArgs {
  String foo<T extends Object>(T x, [int y = 1, int z = 2]) => "$T $x $y $z";
  String bar<T extends Object, U>(T x, {U? y, int z = 3}) => "$T $U $x $y $z";
}
