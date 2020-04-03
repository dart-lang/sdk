// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of general expression as keys in map literals.

library map_literal5_test;

import "package:expect/expect.dart";

void main() {
  test(true);
  test(false);
}

void test(bool b) {
  var m = create(b);
  Expect.equals(b, m.containsKey(true));
  Expect.equals(b, m.containsKey(2));
  Expect.equals(b, m.containsKey(1));
  Expect.equals(!b, m.containsKey(false));
  Expect.equals(!b, m.containsKey("bar"));
  Expect.equals(!b, m.containsKey("foo"));
  if (b) {
    Expect.equals(0, m[true]);
    Expect.equals(3, m[2]);
    Expect.equals(2, m[1]);
  } else {
    Expect.equals(0, m[false]);
    Expect.equals("baz", m["bar"]);
    Expect.equals(2, m["foo"]);
  }
}

Map create(bool b) {
  return {
    b: 0,
    m(b): n(b),
    b ? 1 : "foo": 2,
  };
}

Object m(bool b) => b ? 2 : "bar";
Object n(bool b) => b ? 3 : "baz";
