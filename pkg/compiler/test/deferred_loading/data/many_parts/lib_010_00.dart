// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'libB.dart';

@pragma('dart2js:noInline')
/*member: g_010_00:member_unit=29{b4}*/
g_010_00() {
  Set<String> uniques = {};

  // f_*1*_**;
  f_010_00(uniques, 1);
  f_010_01(uniques, 1);
  f_010_10(uniques, 1);
  f_010_11(uniques, 1);
  f_011_00(uniques, 1);
  f_011_01(uniques, 1);
  f_011_10(uniques, 1);
  f_011_11(uniques, 1);
  f_110_00(uniques, 1);
  f_110_01(uniques, 1);
  f_110_10(uniques, 1);
  f_110_11(uniques, 1);
  f_111_00(uniques, 1);
  f_111_01(uniques, 1);
  f_111_10(uniques, 1);
  f_111_11(uniques, 1);
  Expect.equals(16, uniques.length);
}
