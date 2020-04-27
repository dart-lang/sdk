// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

testNonNullable(A a, B b, C c_dynamic, C<int> c_int, C<String> c_string, D d) {
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
  c_int == c_dynamic; // error
  c_int == c_int; // ok
  c_int == c_string; // error
  c_int == d; // ok}

  c_string == a; // error
  c_string == b; // error
  c_string == c_dynamic; // error
  c_string == c_int; // error
  c_string == c_string; // ok
  c_string == d; // error

  d == a; // error
  d == b; // error
  d == c_dynamic; // error
  d == c_int; // ok
  d == c_string; // error
  d == d; // ok
}

testNullable(
    A? a, B? b, C? c_dynamic, C<int>? c_int, C<String>? c_string, D? d) {
  // Since the receiver type is nullable, the calls are checked against the
  // Object member.

  a == a; // ok
  a == b; // ok
  // TODO(johnniwinther): Awaiting spec update about `==`. Before NNBD these
  // would cause an error but with the current (insufficient) specification for
  // `==` it is ok.
  a == c_dynamic; // ok or error ?
  a == c_int; // ok or error ?
  a == c_string; // ok or error ?
  a == d; // ok or error ?

  b == a; // ok
  b == b; // ok
  b == c_dynamic; // ok or error ?
  b == c_int; // ok or error ?
  b == c_string; // ok or error ?
  b == d; // ok or error ?

  c_dynamic == a; // ok or error ?
  c_dynamic == b; // ok or error ?
  c_dynamic == c_dynamic; // ok
  c_dynamic == c_int; // ok
  c_dynamic == c_string; // ok
  c_dynamic == d; // ok

  c_int == a; // ok or error ?
  c_int == b; // ok or error ?
  c_int == c_dynamic; // ok or error ?
  c_int == c_int; // ok
  c_int == c_string; // ok or error ?
  c_int == d; // ok}

  c_string == a; // ok or error ?
  c_string == b; // ok or error ?
  c_string == c_dynamic; // ok or error ?
  c_string == c_int; // ok or error ?
  c_string == c_string; // ok
  c_string == d; // ok or error ?

  d == a; // ok or error ?
  d == b; // ok or error ?
  d == c_dynamic; // ok or error ?
  d == c_int; // ok
  d == c_string; // ok or error ?
  d == d; // ok
}
