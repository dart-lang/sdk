// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'libB.dart';

@pragma('dart2js:noInline')
/*member: g_001_00:member_unit=25{b3}*/
g_001_00() {
  Set<String> uniques = {};

  // f_**1_**;
  f_001_00(uniques, 2);
  f_001_01(uniques, 2);
  f_001_10(uniques, 2);
  f_001_11(uniques, 2);
  f_011_00(uniques, 2);
  f_011_01(uniques, 2);
  f_011_10(uniques, 2);
  f_011_11(uniques, 2);
  f_101_00(uniques, 2);
  f_101_01(uniques, 2);
  f_101_10(uniques, 2);
  f_101_11(uniques, 2);
  f_111_00(uniques, 2);
  f_111_01(uniques, 2);
  f_111_10(uniques, 2);
  f_111_11(uniques, 2);
  Expect.equals(16, uniques.length);
}
