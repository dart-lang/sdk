// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

var x1 = {1: 'x', 2: 'y'};
test1() {
  x1[3] = 'z';
  x1[ /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x1[ /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0] = 'u';
  x1[3] = /*error:INVALID_ASSIGNMENT*/ 42;
  Map<num, String> y = x1;
}

var x2 = {1: 'x', 2: 'y', 3.0: new RegExp('.')};
test2(Pattern p) {
  x2[3] = 'z';
  x2[ /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x2[4.0] = 'u';
  x2[3] = /*error:INVALID_ASSIGNMENT*/ 42;
  x2[2] = p;
  Map<int, String> y = /*error:INVALID_ASSIGNMENT*/ x2;
}

main() {}
