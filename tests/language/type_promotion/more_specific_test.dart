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
  T? e;

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
    x = a.b;
  }
  if (a is C) {
    // No promotion C !<< A.
    x = a.c;
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the class 'A'.
  }
  B b = new B();
  if (b is A) {
    // No promotion B !<< A.
    x = b.b;
  }
  if (x is A) {
    // Promotion A << dynamic.
    y = x.b;
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'b' isn't defined for the class 'A'.
  }
}

testGeneric() {
  var x;
  var y;

  D d1 = new E<B>(null);
  if (d1 is E) {
    // Promotion: E << D.
    x = d1.e;
  }
  if (d1 is E<A>) {
    // Promotion: E<A> << D.
    int a = d1.d;
    //      ^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //         ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'int'.
    String b = d1.d;
    //         ^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'String'.
    x = d1.e;
  }

  D<A> d2 = new E<B>(null);
  if (d2 is E) {
    // No promotion: E !<< D<A>
    x = d2.e;
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'e' isn't defined for the class 'D<A>'.
  }

  D<A> d3 = new E<B>(new B());
  if (d3 is E<B>) {
    // Promotion: E<B> << D<A>
    x = d3.d.b;
    x = d3.e!.b;
  }
}
