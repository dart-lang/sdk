// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of locals potentially mutated.

class A {
  var a = true;
}

class B extends A {
  var b = true;
}

class C extends B {
  var c = true;
}

class D extends A {
  var d = true;
}

class E implements C, D {
  var a = true;
  var b = true;
  var c = true;
  var d = true;
}

void main() {
  A a = new E();
  var b;
  if (a is D && ((a = new D()) != null)) {}
  if (a is D && (b = a.d)) {
    a = A();
  }
  if ((((a) is D) && (b = (a).d))) {
    a = A();
  }
  if (f(a = A()) && a is D) {
    b = a.d;
  }
}

bool f(x) => true;
