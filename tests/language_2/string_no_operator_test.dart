// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var x = "x";
  var y = "y";
  Expect.throws(() => x < y); //# 01: compile-time error
  Expect.throws(() => x <= y); //# 02: compile-time error
  Expect.throws(() => x > y); //# 03: compile-time error
  Expect.throws(() => x >= y); //# 04: compile-time error
  Expect.throws(() => x - y); //# 05: compile-time error
  Expect.throws(() => x * y); //# 06: compile-time error
  Expect.throws(() => x / y); //# 07: compile-time error
  Expect.throws(() => x ~/ y); //# 08: compile-time error
  Expect.throws(() => x % y); //# 09: compile-time error
  Expect.throws(() => x >> y); //# 10: compile-time error
  Expect.throws(() => x << y); //# 11: compile-time error
  Expect.throws(() => x & y); //# 12: compile-time error
  Expect.throws(() => x | y); //# 13: compile-time error
  Expect.throws(() => x ^ y); //# 14: compile-time error
  Expect.throws(() => -x); //# 15: compile-time error
  Expect.throws(() => ~x); //# 16: compile-time error
}
