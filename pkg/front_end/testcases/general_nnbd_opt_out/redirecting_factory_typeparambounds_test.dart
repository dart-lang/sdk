// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The purpose of this test is to check the representation of redirecting
// factory constructors in the case when type parameters of the enclosing class
// are used in type annotations of the parameters of the redirecting factory
// constructor, and one of the type parameters is the upper bound for the other.

library redirecting_factory_constructors.typeparambounds_test;

class X {}

class Y extends X {}

class A<T, S extends T> {
  A(T t, S s);
  factory A.redir(T t, S s) = A<T, S>;
}

main() {
  new A<X, Y>.redir(new X(), new Y());
}
