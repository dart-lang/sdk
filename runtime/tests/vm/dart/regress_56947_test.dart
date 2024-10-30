// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Dart Project Fuzz Tester (1.101).
// Program generated as:
//   dart dartfuzz.dart --seed 466727405 --no-fp --no-ffi --flat
// @dart=2.14

import 'dart:typed_data';

Int16List var11 = Int16List(33);
List<bool> var79 = <bool>[true, false];
Map<int, bool> var109 = <int, bool>{-74: true, -72: false, 34: true};

main() {
  try {
    if (var79[-9223372034707292160]) {
      switch ((var109[var11[-9223372034707292160]]! ? 100 : 200) <<
          (~9223372034707292159)) {}
    }
  } catch (e, st) {
    print("foo throws");
  }
}
