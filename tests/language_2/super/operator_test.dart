// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing super operator calls

import "package:expect/expect.dart";

class A {
  String val = "";
  List things;

  A() : things = ['D', 'a', 'r', 't', 42];

  operator +(String s) {
    val = "${val}${s}";
    return this;
  }

  operator [](i) {
    return things[i];
  }

  operator []=(i, val) {
    return things[i] = val;
  }
}

class B extends A {
  operator +(String s) {
    super + ("${s}${s}"); // Call A.operator+(this, "${s}${s}").
    return this;
  }

  operator [](i) {
    var temp = super[i];
    if (temp is String) {
      return "$temp$temp";
    }
    return temp + temp;
  }

  operator []=(i, val) {
    // Make sure the index expression is only evaluated
    // once in the presence of a compound assignment.
    return super[i++] += val;
  }
}


main() {
  var a = new A();
  a = a + "William"; // operator + of class A.
  Expect.equals("William", a.val);
  Expect.equals("r", a[2]); // operator [] of class A.

  a = new B();
  a += "Tell"; //   operator + of class B.
  Expect.equals("TellTell", a.val);
  Expect.equals("rr", a[2]); // operator [] of class B.

  a[4] = 1; // operator []= of class B.
  Expect.equals(43, a.things[4]);
  Expect.equals(86, a[4]);
}
