// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int x = 0;

test1() {
  var /*@ type=int* */ a = x;
  a = /*error:INVALID_ASSIGNMENT*/ "hi";
  a = 3;
  var /*@ type=int* */ b = y;
  b = /*error:INVALID_ASSIGNMENT*/ "hi";
  b = 4;
  var /*@ type=int* */ c = z;
  c = /*error:INVALID_ASSIGNMENT*/ "hi";
  c = 4;
}

int y = 0; // field def after use
final z = 42; // should infer `int`

main() {}
