// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<S> {
  void f<T>(S x, S y, T z, T w);
}

class D<S> extends A<S> {
  void f<T>(covariant S x, S y, covariant T z, T w) {
    print(x);
    print(y);
    print(z);
    print(w);
  }
}

class E {
  num f = 123;
  num g = 456;
}

class F extends E {
  covariant int f = 123;
  num g = 789;
}

void main() {}
