// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test insures that statically initialized variables, fields, and parameters
// report compile-time errors.

int a = "String"; //# 01: compile-time error

class A {
  static const int c = "String"; //# 02: compile-time error
  final int d = "String"; //# 03: compile-time error
  int e = "String"; //# 04: compile-time error
  A() {
     int f = "String"; //# 05: compile-time error
  }
  method(
      [
     int //# 06: compile-time error
      g = "String"]) {
    return g;
  }
}

main() {}
