// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details.  All rights reserved.  Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

const String realMaxInt64Value = '9223372036854775807';
const String realMinInt64Value = '-9223372036854775808';

const int i21 = 2097152;

main() {
  int minInt64Value = -1 * i21 * i21 * i21;
  minInt64Value = -9223372036854775807 - 1; //# 01: ok
  minInt64Value = -9223372036854775808;     //# 02: ok
  minInt64Value = -(9223372036854775808);   //# 03: compile-time error
  minInt64Value = -(0x8000000000000000);    //# 04: ok
  minInt64Value = 0x8000000000000000;       //# 05: ok
  minInt64Value = -0x8000000000000000;      //# 06: ok

  Expect.equals('$minInt64Value', realMinInt64Value);
  Expect.equals('${minInt64Value - 1}', realMaxInt64Value);

  int maxInt64Value = 1 * i21 * i21 * i21 - 1;
  maxInt64Value = 9223372036854775807;      //# 11: ok
  maxInt64Value = 9223372036854775807;      //# 12: ok
  maxInt64Value = 9223372036854775808 - 1;  //# 13: compile-time error
  maxInt64Value = -9223372036854775808 - 1; //# 14: ok
  maxInt64Value = -9223372036854775809;     //# 15: compile-time error
  maxInt64Value = 0x8000000000000000 - 1;   //# 16: ok
  maxInt64Value = -0x8000000000000000 - 1;  //# 17: ok
  maxInt64Value = -0x8000000000000001;      //# 18: compile-time error
  maxInt64Value = -(0x8000000000000001);    //# 19: ok

  Expect.equals('$maxInt64Value', realMaxInt64Value);
  Expect.equals('${maxInt64Value + 1}', realMinInt64Value);
}
