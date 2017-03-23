// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

get x => 200;

// Ok: can have a setter named x when getter x is defined.
set x(var i) {
  print(i);
}

// Error: there is already a getter for x
int x; //                         //# 00: compile-time error

// Error: there is already a getter named x.
int x(a, b) { print(a + b); } //  //# 01: compile-time error

void main() {
  // No need to reference x.
}
