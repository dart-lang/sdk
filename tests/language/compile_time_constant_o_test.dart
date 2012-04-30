// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test compile-time constants with string-interpolation.

final str = "foo";
final m1 = const { "foo": 499 };
final m2 = const { "$str": 499 };
final m3 = const { "$str": 42, "foo": 499 };
final m4 = const { "foo": 42, "$str": 499 };
final m5 = const { "f" "o" "o": 499 };

final mm1 = const { "afoo#foo": 499 };
final mm2 = const { "a$str#$str": 499 };
final mm3 = const { "a" "$str" "#" "foo": 499 };
final mm4 = const { "a$str" "#$str": 499 };

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
