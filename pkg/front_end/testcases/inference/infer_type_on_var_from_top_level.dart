// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int x = 0;

test1() {
  var a = x;
  a = /*error:INVALID_ASSIGNMENT*/ "hi";
  a = 3;
  var b = y;
  b = /*error:INVALID_ASSIGNMENT*/ "hi";
  b = 4;
  var c = z;
  c = /*error:INVALID_ASSIGNMENT*/ "hi";
  c = 4;
}

int y = 0; // field def after use
final z = 42; // should infer `int`

main() {}
