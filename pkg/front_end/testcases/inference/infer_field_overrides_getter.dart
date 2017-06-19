// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {
  int get x;
}

class B {
  int get x => 0;
}

class C extends A {
  var /*@topType=int*/ x;
}

class D extends B {
  var /*@topType=int*/ x;
}

class E implements A {
  var /*@topType=int*/ x;
}

class F implements B {
  var /*@topType=int*/ x;
}

class G extends Object with B {
  var /*@topType=int*/ x;
}

main() {}
