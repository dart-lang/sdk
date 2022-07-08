// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

/*@testedFeatures=inference*/

class A {
  A f(A x, {A? y}) => throw '';
  A g(A x, {A? y}) => throw '';
  A h(A x, {A? y}) => throw '';
}

class B extends A implements I {
  f(x, {y}) => throw '';
  g(x, {y}) => throw '';
  h(x, {y}) => throw '';
}

class I {
  I f(I x, {I? y}) => throw '';
  A g(I x, {I? y}) => throw '';
  A h(A x, {I? y}) => throw '';
}

main() {}
