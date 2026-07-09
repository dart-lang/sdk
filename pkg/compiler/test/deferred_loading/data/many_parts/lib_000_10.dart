// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'libB.dart';

@pragma('dart2js:noInline')
/*member: g_000_10:member_unit=17{b2}*/
g_000_10() {
  Set<String> uniques = {};

  // f_***_1*;
  f_000_10(uniques, 3);
  f_000_11(uniques, 3);
  f_001_10(uniques, 3);
  f_001_11(uniques, 3);
  f_010_10(uniques, 3);
  f_010_11(uniques, 3);
  f_011_10(uniques, 3);
  f_011_11(uniques, 3);
  f_100_10(uniques, 3);
  f_100_11(uniques, 3);
  f_101_10(uniques, 3);
  f_101_11(uniques, 3);
  f_110_10(uniques, 3);
  f_110_11(uniques, 3);
  f_111_10(uniques, 3);
  f_111_11(uniques, 3);
  Expect.equals(16, uniques.length);
}
