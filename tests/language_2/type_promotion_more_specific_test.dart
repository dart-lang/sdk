// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test use of more specific in type promotion of interface types.

class A {
  var a;
}

class B extends A {
  var b;
}

class C {
  var c;
}

class D<T> {
  T d;

  D(this.d);
}

class E<T> extends D<T> {
  T e;

  E(e)
      : this.e = e,
        super(e);
}

void main() {
  testInterface();
  testGeneric();
}

void testInterface() {
  var x;
  var y;

  A a = new B();
  if (a is B) {
    // Promotion B << A.
    x = a.b; //# 01: ok
  }
  if (a is C) {
    // No promotion C !<< A.
    x = a.c; //# 02: compile-time error
  }
  B b = new B();
  if (b is A) {
    // No promotion B !<< A.
    x = b.b; //# 03: ok
  }
  if (x is A) {
    // No promotion: x has type dynamic.
    y = x.b; //# 04: ok
  }
}

testGeneric() {
  var x;
  var y;

  D d1 = new E<B>(null);
  if (d1 is E) {
    // Promotion: E << D.
    x = d1.e; //# 05: ok
  }
  if (d1 is E<A>) {
    // Promotion: E<A> << D.
    int a = d1.d; //# 06: compile-time error
    String b = d1.d; //# 07: compile-time error
    x = d1.e; //# 08: ok
  }

  D<A> d2 = new E<B>(null);
  if (d2 is E) {
    // No promotion: E !<< D<A>
    x = d2.e; //# 09: compile-time error
  }

  D<A> d3 = new E<B>(new B());
  if (d3 is E<B>) {
    // Promotion: E<B> << D<A>
    x = d3.d.b; //# 12: ok
    x = d3.e.b; //# 13: ok
  }
}
