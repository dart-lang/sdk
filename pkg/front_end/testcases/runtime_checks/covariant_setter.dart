// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  T x;
  void set y(T value) {}
  void f(T value) {
    this.x = value;
    this.y = value;
  }
}

void g(C<num> c) {
  c.x = 1.5;
  c.y = 1.5;
}

void main() {}
