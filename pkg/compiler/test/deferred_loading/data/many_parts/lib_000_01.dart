// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'libB.dart';

@pragma('dart2js:noInline')
/*member: g_000_01:member_unit=2{b1}*/
g_000_01() {
  Set<String> uniques = {};

  // f_***_*1;
  f_000_01(uniques, 4);
  f_000_11(uniques, 4);
  f_001_01(uniques, 4);
  f_001_11(uniques, 4);
  f_010_01(uniques, 4);
  f_010_11(uniques, 4);
  f_011_01(uniques, 4);
  f_011_11(uniques, 4);
  f_100_01(uniques, 4);
  f_100_11(uniques, 4);
  f_101_01(uniques, 4);
  f_101_11(uniques, 4);
  f_110_01(uniques, 4);
  f_110_11(uniques, 4);
  f_111_01(uniques, 4);
  f_111_11(uniques, 4);
  Expect.equals(16, uniques.length);
}
