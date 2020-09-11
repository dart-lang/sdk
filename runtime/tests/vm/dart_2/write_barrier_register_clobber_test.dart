// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test attempts to verify that write barrier slow path does not
// clobber any live values.

import 'dart:_internal' show VMInternalsForTesting;

import 'package:expect/expect.dart';

class Old {
  var f;
  Old(this.f);
}

@pragma('vm:never-inline')
int crashy(int v, List<Old> oldies) {
  // This test attempts to create a lot of live values which would live across
  // write barrier invocation so that when write-barrier calls runtime and
  // clobbers a register this is detected.
  var young = Object();
  var len = oldies.length;
  var i = 0;
  var v00 = v + 0;
  var v01 = v + 1;
  var v02 = v + 2;
  var v03 = v + 3;
  var v04 = v + 4;
  var v05 = v + 5;
  var v06 = v + 6;
  var v07 = v + 7;
  var v08 = v + 8;
  var v09 = v + 9;
  var v10 = v + 10;
  var v11 = v + 11;
  var v12 = v + 12;
  var v13 = v + 13;
  var v14 = v + 14;
  var v15 = v + 15;
  var v16 = v + 16;
  var v17 = v + 17;
  var v18 = v + 18;
  var v19 = v + 19;
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
  final init = args.contains('impossible') ? 1 : 0;
  final oldies = List<Old>.generate(100000, (i) => Old(""));
  VMInternalsForTesting.collectAllGarbage();
  VMInternalsForTesting.collectAllGarbage();
  Expect.equals(crashy(init, oldies), 190);
  for (var o in oldies) {
    Expect.isTrue(o.f is! String);
  }
}
