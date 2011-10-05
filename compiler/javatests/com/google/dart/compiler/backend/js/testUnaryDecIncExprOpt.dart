// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Main {
  static void main(int _marker_3) {
    int _marker_0 = 0;

    // Ensure that ++_marker_0 remains ++_marker_0 on simple assignment
    int i = ++_marker_0;

    // Ensure that _marker_1++ remains _marker_1++ when used in a for loop
    for (int _marker_1 = 0; _marker_1 < 10; _marker_1++) {
    }

    // Ensure that --_marker_0 remains --_marker_0 on simple assignment
    int j = --_marker_0;

    // Ensure that _marker_2-- remains _marker_2-- when used in a for loop
    for (int _marker_2 = 10; _marker_2 >= 0; _marker_2--) {
    }

    // Ensure that parameter _marker_3 remains as _marker_3++ 
    _marker_3++;

    // Ensure that parameter _marker_3 remains as --_marker_3
    --_marker_3;

    // Ensure binary op is inlined (variable).
    int _marker_4;
    i = ~_marker_4;

    // Ensure binary op is inlined (parameter).
    i = ~_marker_3;

    // Ensure binary op is inlined (field).
    A a = new A();
    i = ~a.field_0;

    // Ensure untyped operand is not inlined
    var foo;
    int _marker_5;
    _marker_5 = ~foo;

    // Ensure binary op is not inlined (abstract field).
    A aa = new B();
    i = ++aa.field_1;

    // Ensure binary op is not inlined (abstract field).
    A aaa = new B();
    i = ++aaa.field_2;
  }
}

class A {
  A() { }
  int field_0;
  int field_1;
  int field_2;
}

class B extends A {
  B() : super() { }
  int get field_1() { }
  set field_2(x) { }
}

main() {
  Main.main(0);
}
