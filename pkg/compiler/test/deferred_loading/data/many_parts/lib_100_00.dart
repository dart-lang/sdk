// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'libB.dart';

@pragma('dart2js:noInline')
/*member: g_100_00:member_unit=31{b5}*/
g_100_00() {
  Set<String> uniques = {};

  // f_1**_**;
  f_100_00(uniques, 0);
  f_100_01(uniques, 0);
  f_100_10(uniques, 0);
  f_100_11(uniques, 0);
  f_101_00(uniques, 0);
  f_101_01(uniques, 0);
  f_101_10(uniques, 0);
  f_101_11(uniques, 0);
  f_110_00(uniques, 0);
  f_110_01(uniques, 0);
  f_110_10(uniques, 0);
  f_110_11(uniques, 0);
  f_111_00(uniques, 0);
  f_111_01(uniques, 0);
  f_111_10(uniques, 0);
  f_111_11(uniques, 0);
  Expect.equals(16, uniques.length);
}
