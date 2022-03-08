// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to check the representation of redirecting
// factory constructors in the case when type parameters of the enclosing class
// are used in type annotations of the parameters of the redirecting factory
// constructor.

library redirecting_factory_constructors.typeparam_test;

class A<T, S> {
  A(T t, S s);
  factory A.redir(T t, S s) = A<T, S>;
}

main() {
  new A<int, String>.redir(42, "foobar");
}
