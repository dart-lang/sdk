// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

class M {
  int compareTo(int x) {
    return x.isEven ? 37 : -37;
  }
}

// All of these should work the same for the purposes of calling through
// the Comparable interface.

class C extends M implements Comparable<int> {}

class D extends Object with M implements Comparable<int> {}

class E = Object with M implements Comparable<int>;

/// Regression test for https://github.com/dart-lang/sdk/issues/30669, DDC was
/// not attaching the "extension member" symbol to call `Comparable.compareTo` in
/// some cases.
main() {
  testComparable(new C());
  testComparable(new D());
  testComparable(new E());
}

testComparable(Comparable<Object> c) {
  Expect.equals(c.compareTo(42), 37, '$c');
  Expect.equals(c.compareTo(41), -37, '$c');
  if (checkedParameters) {
    Expect.throws(() => print(c.compareTo("42")));
  }
}
