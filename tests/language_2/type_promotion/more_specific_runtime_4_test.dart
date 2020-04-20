// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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

  }
  if (a is C) {
    // No promotion C !<< A.

  }
  B b = new B();
  if (b is A) {
    // No promotion B !<< A.

  }
  if (x is A) {
    // Promotion A << dynamic.

  }
}

testGeneric() {
  var x;
  var y;

  D d1 = new E<B>(null);
  if (d1 is E) {
    // Promotion: E << D.

  }
  if (d1 is E<A>) {
    // Promotion: E<A> << D.


    x = d1.e;
  }

  D<A> d2 = new E<B>(null);
  if (d2 is E) {
    // No promotion: E !<< D<A>

  }

  D<A> d3 = new E<B>(new B());
  if (d3 is E<B>) {
    // Promotion: E<B> << D<A>


  }
}
