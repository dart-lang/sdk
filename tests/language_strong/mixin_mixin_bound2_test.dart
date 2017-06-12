// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class I<T> {}

class J<T> {}

class K<T> {}

class S<U extends Set<V>, V> {}

class M<U, V, T extends Map<U, V>> {
  m() {
    return T;
  }
}

class A<U, V extends Set<U>> = Object with M<U, V, Map<U, V>> implements I<V>;

class B<T extends List<num>> = Object with A<T, Set<T>> implements J<T>;

class C<T extends num> = S<Set<T>, T> with B<List<T>> implements K<T>;

main() {
  var c = new C<int>();
  Expect.equals("Map<List<int>, Set<List<int>>>", c.m().toString());
  Expect.isTrue(c is K<int>);
  Expect.isTrue(c is J<List<int>>);
  Expect.isTrue(c is I<Set<List<int>>>);
  Expect.isTrue(c is S<Set<int>, int>);
  Expect.isTrue(c is A<List<int>, Set<List<int>>>);
  Expect.isTrue(
      c is M<List<int>, Set<List<int>>, Map<List<int>, Set<List<int>>>>);
}
