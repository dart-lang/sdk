// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--throw_on_javascript_int_overflow


import "package:expect/expect.dart";

int literals() {
  var okay_literal = 0xFFFFFFFFFFFFF;
  var too_big_literal = 0x1FFFFFFFFFFFFF;  /// 01: compile-time error
  return okay_literal;
}

main() {
  Expect.equals(0xFFFFFFFFFFFFF, literals());
}
