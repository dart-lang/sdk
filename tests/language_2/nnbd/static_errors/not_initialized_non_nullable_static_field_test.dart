// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if a static field non-nullable type has no
// initializer expression.
void main() {}

class A {
  static int v; //# 01: compile-time error
  static int v = 0; //# 02: ok
  static int? v; //# 03: ok
  static int? v = 0; //# 04: ok
  static dynamic v; //# 05: ok
  static var v; //# 06: ok
  static void v; //# 07: ok
  static Never v; //# 08: compile-time error
}
