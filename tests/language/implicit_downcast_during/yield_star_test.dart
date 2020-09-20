// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

Iterable<B> f(Iterable<A> a) sync* {
  yield* a;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
  // [cfe] A value of type 'Iterable<A>' can't be assigned to a variable of type 'Iterable<B>'.
}

void main() {
  B b = new B();
  for (var x in f(<B>[b])) {}
}
