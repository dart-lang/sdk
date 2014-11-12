// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

main() {
  final val = (0xffb15062).toSigned(32);
  final arr = new Int32x4List(1);
  arr[0] = new Int32x4(val, val, val, val);
  Expect.equals(val, arr[0].x);
  Expect.equals(val, arr[0].y);
  Expect.equals(val, arr[0].z);
  Expect.equals(val, arr[0].w);
}

