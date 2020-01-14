// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int x = 100;

get x => 200; //                //# 00: compile-time error
set x(var i) { print(i); } //     //# 01: compile-time error

int x(a, b) { print(a + b); } //  //# 02: compile-time error

void main() {
  // No need to reference x.
}
