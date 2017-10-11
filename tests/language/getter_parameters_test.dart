// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a getter has no parameters.

get f1 => null;
get f2
() //# 01: compile-time error
    => null;
get f3
(arg) //# 02: compile-time error
    => null;
get f4
([arg]) //# 03: compile-time error
    => null;
get f5
({arg}) //# 04: compile-time error
    => null;

main() {
  f1;
  f2;
  f3;
  f4;
  f5;
}
