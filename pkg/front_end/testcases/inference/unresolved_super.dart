// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class C {
  void test() {
    var /*@type=dynamic*/ v1 = super.foo(/*@typeArgs=dynamic*/ f());
    var /*@type=dynamic*/ v2 = super.bar;
    var /*@type=dynamic*/ v3 = super[0];
    var /*@type=dynamic*/ v4 = super.bar = /*@typeArgs=dynamic*/ f();
    var /*@type=dynamic*/ v5 = super[0] = /*@typeArgs=dynamic*/ f();
  }
}

main() {}
