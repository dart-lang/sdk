// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test insures that statically initialized variables, fields, and parameters
// report static type warnings.

int a = "String"; // //# 01: static type warning, dynamic type error

class A {
  static const int c = "String"; //# 02: static type warning, checked mode compile-time error
  final int d = "String"; //# 03: static type warning, dynamic type error
  int e = "String"; //# 04: static type warning, dynamic type error
  A() {
     int f = "String"; //# 05: static type warning, dynamic type error
  }
  method(
      [
     int // //# 06: static type warning
      g = "String"]) {
    return g;
  }
}

int main() {
  var w = a; //# 01: continued
  var x;
  x = A.c; // //# 02: continued
  var v = new A();
  x = v.d; // //# 03: continued
  x = v.e; // //# 04: continued
      x = v.method(1); //# 06: continued
}
