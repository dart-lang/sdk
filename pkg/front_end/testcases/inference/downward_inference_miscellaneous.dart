// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef T Function2<S, T>(S x);

class A<T> {
  Function2<T, T> x;
  A(this.x);
}

void main() {
  {
    // Variables, nested literals
    var /*@type=String*/ x = "hello";
    var /*@type=int*/ y = 3;
    void f(List<Map<int, String>> l) {}
    ;
    f(/*@typeArgs=Map<int, String>*/ [
      /*@typeArgs=int, String*/ {y: x}
    ]);
  }
  {
    int f(int x) => 0;
    A<int> a = new /*@typeArgs=int*/ A(f);
  }
}
