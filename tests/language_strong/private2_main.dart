// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing access to private fields across class hierarchies.

part of Private2Test;

class A {
  var _f;
  var g;
  A()
      : _f = 42,
        g = 43;
}

class C extends B {
  C() : super();
}

main() {
  var a = new A();
  print(a.g);
  print(a._f);
  var o = new C();
  print(o.g); // Access to public field in A.
  print(o._f); // Access to private field in A is allowed.
}
