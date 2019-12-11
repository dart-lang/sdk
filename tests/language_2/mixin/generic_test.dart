// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S<T> {
  s() {
    return T;
  }
}

class M<T> {
  m() {
    return T;
  }
}

class N<T> {
  n() {
    return T;
  }
}

class C<U, V> extends S<Map<U, V>> with M<List<U>>, N<Set<V>> {}

main() {
  var c = new C<int, bool>();
  Expect.isTrue(c is S<Map<int, bool>>);
  Expect.equals("Map<int, bool>", c.s().toString());
  Expect.isTrue(c is M<List<int>>);
  Expect.equals("List<int>", c.m().toString());
  Expect.isTrue(c is N<Set<bool>>);
  Expect.equals("Set<bool>", c.n().toString());
}
