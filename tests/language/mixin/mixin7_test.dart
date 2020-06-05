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

class A<U, V> = Object with M implements I<V>; // M is raw.

class B<T> = Object with A implements J<T>; // A is raw.

class C<T> = S<List<T>> with B implements K<T>; // B is raw.

main() {
  var c = new C<int>();
  Expect.equals("dynamic", c.m().toString());
  Expect.isTrue(c is K<int>);
  Expect.isTrue(c is J);
  Expect.isTrue(c is I);
  Expect.isTrue(c is S<List<int>>);
  Expect.isTrue(c is A);
  Expect.isTrue(c is M);
}
