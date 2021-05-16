// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests invocations of instance functions with const functions.

import "package:expect/expect.dart";

class A {
  const A();
}

class B {
  const B();

  @override
  String toString() => "B";
}

class C {
  final int y;

  const C(this.y);

  int fn() {
    if (y == 1) return 100;
    return 200;
  }
}

class D extends C {
  const D(int y) : super(y);

  @override
  int fn() => 300;
}

class E extends C {
  const E(int y) : super(y);
}

class F<T, U, V> {
  const F();
  U fn(U x) => x;
}

class G<T> extends F<T, String, num> {
  const G();
}

const var1 = fn();
String fn() => const A().toString();

const toString1 = const A().toString();

const var2 = fn2();
String fn2() => const B().toString();

const toString2 = const B().toString();

const var3 = fn3();
const var4 = fn4();
int fn3() => const C(0).fn();
int fn4() => const C(1).fn();

const fnVal1 = const C(0).fn();
const fnVal2 = const C(1).fn();

const var5 = fn5();
int fn5() => const D(1).fn();

const fnVal3 = const D(1).fn();

const var6 = fn6();
int fn6() => const E(1).fn();

const fnVal4 = const E(0).fn();

const var7 = fn7();
String fn7() => const F<int, String, num>().fn("string");

const fnVal5 = const F<int, String, num>().fn("string");

const var8 = fn8();
String fn8() => const G<int>().fn("string");

const fnVal6 = const G<int>().fn("string");

void main() {
  Expect.equals(var1, const A().toString());
  Expect.equals(toString1, const A().toString());
  Expect.equals(var2, const B().toString());
  Expect.equals(toString2, const B().toString());
  Expect.equals(var3, 200);
  Expect.equals(var4, 100);
  Expect.equals(fnVal1, 200);
  Expect.equals(fnVal2, 100);
  Expect.equals(var5, 300);
  Expect.equals(fnVal3, 300);
  Expect.equals(var6, 100);
  Expect.equals(fnVal4, 200);
  Expect.equals(var7, "string");
  Expect.equals(fnVal5, "string");
  Expect.equals(var8, "string");
  Expect.equals(fnVal6, "string");
}
