// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

extension type C(Object? o) {}

extension type D(Object o) {}

extension type E(B it) implements A {}

extension type F(B it) implements E, B {}

extension type G<T>(T o) {}

test<T1, T2 extends A>(
    Object o,
    A a,
    B b,
    C c,
    D d,
    E e,
    F f,
    G<T1> g1,
    G<T2> g2) {

  o = o; // Ok
  o = a; // Ok
  o = b; // Ok
  o = c; // Error
  o = d; // Ok
  o = e; // Ok
  o = f; // Ok
  o = g1; // Error
  o = g2; // Ok

  a = o; // Error
  a = a; // Ok
  a = b; // Ok
  a = c; // Error
  a = d; // Error
  a = e; // Ok
  a = f; // Ok
  a = g1; // Error
  a = g2; // Error

  b = o; // Error
  b = a; // Error
  b = b; // Ok
  b = c; // Error
  b = d; // Error
  b = e; // Error
  b = f; // Ok
  b = g1; // Error
  b = g2; // Error

  c = o; // Error
  c = a; // Error
  c = b; // Error
  c = c; // Ok
  c = d; // Error
  c = e; // Error
  c = f; // Error
  c = g1; // Error
  c = g2; // Error

  d = o; // Error
  d = a; // Error
  d = b; // Error
  d = c; // Error
  d = d; // Ok
  d = e; // Error
  d = f; // Error
  d = g1; // Error
  d = g2; // Error

  e = o; // Error
  e = a; // Error
  e = b; // Error
  e = c; // Error
  e = d; // Error
  e = e; // Ok
  e = f; // Ok
  e = g1; // Error
  e = g2; // Error

  f = o; // Error
  f = a; // Error
  f = b; // Error
  f = c; // Error
  f = d; // Error
  f = e; // Error
  f = f; // Ok
  f = g1; // Error
  f = g2; // Error

  g1 = o; // Error
  g1 = a; // Error
  g1 = b; // Error
  g1 = c; // Error
  g1 = d; // Error
  g1 = e; // Error
  g1 = f; // Error
  g1 = g1; // Ok
  g1 = g2; // Error

  g2 = o; // Error
  g2 = a; // Error
  g2 = b; // Error
  g2 = c; // Error
  g2 = d; // Error
  g2 = e; // Error
  g2 = f; // Error
  g2 = g1; // Error
  g2 = g2; // Ok
}