// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test attempts to verify that write barrier slow path does not
// clobber any live values.

import 'dart:_internal' show VMInternalsForTesting;
import 'dart:typed_data';

import 'package:expect/expect.dart';

class Old {
  var f;
  Old(this.f);
}

@pragma('vm:never-inline')
Float64x2 crashy(Float64x2 v, List<Old> oldies) {
  // This test attempts to create a lot of live values which would live across
  // write barrier invocation so that when write-barrier calls runtime and
  // clobbers a register this is detected.
  var young = Object();
  var len = oldies.length;
  var i = 0;
  var v00 = v + Float64x2(0.0, 0.0);
  var v01 = v + Float64x2(1.0, 1.0);
  var v02 = v + Float64x2(2.0, 2.0);
  var v03 = v + Float64x2(3.0, 3.0);
  var v04 = v + Float64x2(4.0, 4.0);
  var v05 = v + Float64x2(5.0, 5.0);
  var v06 = v + Float64x2(6.0, 6.0);
  var v07 = v + Float64x2(7.0, 7.0);
  var v08 = v + Float64x2(8.0, 8.0);
  var v09 = v + Float64x2(9.0, 9.0);
  var v10 = v + Float64x2(10.0, 10.0);
  var v11 = v + Float64x2(11.0, 11.0);
  var v12 = v + Float64x2(12.0, 12.0);
  var v13 = v + Float64x2(13.0, 13.0);
  var v14 = v + Float64x2(14.0, 14.0);
  var v15 = v + Float64x2(15.0, 15.0);
  var v16 = v + Float64x2(16.0, 16.0);
  var v17 = v + Float64x2(17.0, 17.0);
  var v18 = v + Float64x2(18.0, 18.0);
  var v19 = v + Float64x2(19.0, 19.0);
  while (i < len) {
    // Eventually this will overflow store buffer and call runtime to acquire
    // a new block.
    oldies[i++].f = young;
  }
  return v00 +
      v01 +
      v02 +
      v03 +
      v04 +
      v05 +
      v06 +
      v07 +
      v08 +
      v09 +
      v10 +
      v11 +
      v12 +
      v13 +
      v14 +
      v15 +
      v16 +
      v17 +
      v18 +
      v19;
}

void main(List<String> args) {
  final init =
      args.contains('impossible') ? Float64x2(1.0, 1.0) : Float64x2(0.0, 0.0);
  final oldies = List<Old>.generate(100000, (i) => Old(""));
  VMInternalsForTesting.collectAllGarbage();
  VMInternalsForTesting.collectAllGarbage();
  var r = crashy(init, oldies);
  Expect.equals(r.x, 190.0);
  Expect.equals(r.y, 190.0);
  for (var o in oldies) {
    Expect.isTrue(o.f is! String);
  }
}
