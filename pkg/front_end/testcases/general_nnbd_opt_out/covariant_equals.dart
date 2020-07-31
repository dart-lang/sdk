// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A {
  bool operator ==(covariant A other) => true;
}

class B extends A {
  bool operator ==(other) => true;
}

class C<T> {
  bool operator ==(covariant C<T> other) => true;
}

class D extends C<int> {}

main() {}

test(A a, B b, C c_dynamic, C<int> c_int, C<String> c_string, D d) {
  a == a; // ok
  a == b; // ok
  a == c_dynamic; // error
  a == c_int; // error
  a == c_string; // error
  a == d; // error

  b == a; // ok
  b == b; // ok
  b == c_dynamic; // error
  b == c_int; // error
  b == c_string; // error
  b == d; // error

  c_dynamic == a; // error
  c_dynamic == b; // error
  c_dynamic == c_dynamic; // ok
  c_dynamic == c_int; // ok
  c_dynamic == c_string; // ok
  c_dynamic == d; // ok

  c_int == a; // error
  c_int == b; // error
  c_int == c_dynamic; // ok
  c_int == c_int; // ok
  c_int == c_string; // error
  c_int == d; // ok}

  c_string == a; // error
  c_string == b; // error
  c_string == c_dynamic; // ok
  c_string == c_int; // error
  c_string == c_string; // ok
  c_string == d; // error

  d == a; // error
  d == b; // error
  d == c_dynamic; // ok
  d == c_int; // ok
  d == c_string; // error
  d == d; // ok
}
