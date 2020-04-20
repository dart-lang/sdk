// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class I<T> {}

class J<T> {}

class K<T> {}

class S<T> {}

class M<T> {
  m() {
    return T;
  }
}

class A<U, V> = Object with M<Map<U, V>> implements I<V>;

class B<T> = Object with A<T, Set<T>> implements J<T>;

class C<T> = S<List<T>> with B<List<T>> implements K<T>;

main() {
  var c = new C<int>();
  Expect.equals("Map<List<int>, Set<List<int>>>", c.m().toString());
  Expect.isTrue(c is K<int>);
  Expect.isTrue(c is J<List<int>>);
  Expect.isTrue(c is I<Set<List<int>>>);
  Expect.isTrue(c is S<List<int>>);
  Expect.isTrue(c is A<List<int>, Set<List<int>>>);
  Expect.isTrue(c is M<Map<List<int>, Set<List<int>>>>);
}
