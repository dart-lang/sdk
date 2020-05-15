// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Casts in constants correctly substitute type variables.

class A {
  const A();
}

class B implements A {
  const B();
}

class M<T extends A> {
  final T a;
  const M(dynamic t) : a = t; // adds implicit cast `as T`
}

class N<S extends A> extends M<S> {
  const N(dynamic t) : super(t);
}

main() {
  print(const N<B>(const B()));
}
