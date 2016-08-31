// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Integer literals.
  Expect.isTrue(2is int);
  Expect.equals(2, 2as int);
  Expect.isTrue(-2is int);
  Expect.equals(-2, -2as int);
  Expect.isTrue(0x10is int);
  Expect.isTrue(-0x10is int);
  // "a" will be part of hex literal, the following "s" is an error.
  0x10as int;  /// 01: compile-time error
  0x;          /// 04: compile-time error

  // Double literals.
  Expect.isTrue(2.0is double);
  Expect.equals(2.0, 2.0as double);
  Expect.isTrue(-2.0is double);
  Expect.equals(-2.0, -2.0as double);
  Expect.isTrue(.2is double);
  Expect.equals(0.2, .2as double);
  Expect.isTrue(1e2is double);
  Expect.equals(1e2, 1e2as double);
  Expect.isTrue(1e-2is double);
  Expect.equals(1e-2, 1e-2as double);
  Expect.isTrue(1e+2is double);
  Expect.equals(1e+2, 1e+2as double);
  Expect.throws(() => 1.e+2,                       /// 05: ok
                (e) => e is NoSuchMethodError);    /// 05: continued
  1d;  /// 06: compile-time error
  1D;  /// 07: compile-time error
  Expect.throws(() => 1.d+2,                       /// 08: ok
                (e) => e is NoSuchMethodError);    /// 08: continued
  Expect.throws(() => 1.D+2,                       /// 09: ok
                (e) => e is NoSuchMethodError);    /// 09: continued
  1.1d;  /// 10: compile-time error
  1.1D;  /// 11: compile-time error
  1e;  /// 02: compile-time error
  1x;  /// 03: compile-time error
}
