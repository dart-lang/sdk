// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.equals(42, FOO);   /// 01: compile-time error
  Expect.equals(87, BAR);   /// 02: compile-time error
  Expect.equals(42, C.FOO); /// 03: compile-time error
  Expect.equals(87, C.FOO); /// 04: compile-time error
}

const FOO = 42;     /// 01: continued
const int BAR = 87; /// 02: continued

class C {
  static const FOO = 42;     /// 03: continued
  static const int BAR = 87; /// 04: continued
}
