// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test(dynamic d, Object o, Function f) {
  d(); //# 01: ok
  o(); //# 02: compile-time error
  f(); //# 03: ok
  d.call; //# 04: ok
  o.call; //# 05: compile-time error
  f.call; //# 06: ok
  d.call(); //# 07: ok
  o.call(); //# 08: compile-time error
  f.call(); //# 09: ok
}

main() {}
