// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  List<int> list;
  A(int a, int b) : list = <int>[a, b];
  operator [](index) => list[index];
  operator []=(index, value) => list[index] = value;
}

class B {
  int value;
  List trace;
  B(this.trace) : value = 100;
  operator [](index) {
    trace.add(-3);
    trace.add(index);
    trace.add(this.value);
    this.value = this.value + 1;
    return this;
  }

  operator []=(index, value) {
    trace.add(-5);
    trace.add(index);
    trace.add(value.value);
    this.value = this.value + 1;
  }

  operator +(int value) {
    trace.add(-4);
    trace.add(this.value);
    trace.add(value);
    this.value = this.value + 1;
    return this;
  }
}

B getB(trace) {
  trace.add(-1);
  return new B(trace);
}

int getIndex(trace) {
  trace.add(-2);
  return 42;
}

main() {
  A a = new A(1, 2);
  Expect.equals(1, a[0]);
  Expect.equals(2, a[1]);

  Expect.equals(1, a[0]++);
  Expect.equals(2, a[0]);

  Expect.equals(2, a[0]--);
  Expect.equals(1, a[0]);

  Expect.equals(0, --a[0]);
  Expect.equals(0, a[0]);

  Expect.equals(1, ++a[0]);
  Expect.equals(1, a[0]);

  a[0] += 2;
  Expect.equals(3, a[0]);

  List trace = new List();
  getB(trace)[getIndex(trace)] += 37;

  Expect.listEquals([-1, -2, -3, 42, 100, -4, 101, 37, -5, 42, 102], trace);
}
