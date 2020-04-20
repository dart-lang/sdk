// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {
  void set x(int value);
}

class B {
  void set x(int value) {}
}

class C extends A {
  var x;
}

class D extends B {
  var x;
}

class E implements A {
  var x;
}

class F implements B {
  var x;
}

class G extends Object with B {
  var x;
}

main() {}
