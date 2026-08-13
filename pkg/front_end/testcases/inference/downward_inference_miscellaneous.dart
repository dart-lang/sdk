// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef T Function2<S, T>(S x);

class A<T> {
  Function2<T, T> x;
  A(this.x);
}

void main() {
  {
    // Variables, nested literals
    var x = "hello";
    var y = 3;
    void f(List<Map<int, String>> l) {}
    ;
    f([
      {y: x},
    ]);
  }
  {
    int f(int x) => 0;
    A<int> a = new A(f);
  }
}
