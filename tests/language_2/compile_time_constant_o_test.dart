// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test compile-time constants with string-interpolation.

import "package:expect/expect.dart";

const str = "foo";
const m1 = const {"foo": 499};
const m2 = const {"$str": 499};
const m3 = const {
  // Causes in a duplicate key error.
  "$str": 42, //# 01: compile-time error
  "foo": 499
};
const m4 = const {
  // Causes in a duplicate key error.
  "foo": 42, //# 02: compile-time error
  "$str": 499
};
const m5 = const {"f" "o" "o": 499};

const mm1 = const {"afoo#foo": 499};
const mm2 = const {"a$str#$str": 499};
const mm3 = const {"a" "$str" "#" "foo": 499};
const mm4 = const {"a$str" "#$str": 499};

main() {
  Expect.equals(1, m1.length);
  Expect.equals(499, m1["foo"]);
  Expect.identical(m1, m2);
  Expect.identical(m1, m3);
  Expect.identical(m1, m4);
  Expect.identical(m1, m5);

  Expect.equals(1, mm1.length);
  Expect.equals(499, mm1["afoo#foo"]);
  Expect.identical(mm1, mm2);
  Expect.identical(mm1, mm3);
  Expect.identical(mm1, mm4);
}
