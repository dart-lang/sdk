// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class I<T> {}

class J<T> {}

class S<U extends Set<V>, V> {}

class M<U, V, T extends Map<U, V>> {
  t() {
    return T;
  }
}

class A<U, V extends List> = Object with M<U, V, Map<U, V>> implements I<V>;

class C<T, K> = S<Set<T>, T> with A<T, List<K>> implements J<K>;

main() {
  var c = new C<int, bool>();
  Expect.equals("Map<int, List<bool>>", c.t().toString());
  Expect.isTrue(c is I<List<bool>>);
  Expect.isTrue(c is J<bool>);
  Expect.isTrue(c is S<Set<int>, int>);
  Expect.isTrue(c is A<int, List<bool>>);
  Expect.isTrue(c is M<int, List<bool>, Map<int, List<bool>>>);
}
