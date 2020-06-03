// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test symbol literals with underscores.
// These are currently unsupported by dart2js.

library symbol_literal_test;

main() {
  print(#a);
  print(#_a); //# 01: compile-time error

  print(#a.b);
  print(#_a.b); //# 02: compile-time error
  print(#a._b); //# 03: compile-time error

  print(#a.b.c);
  print(#_a.b.c); //# 04: compile-time error
  print(#a._b.c); //# 05: compile-time error
  print(#a.b._c); //# 06: compile-time error
}
