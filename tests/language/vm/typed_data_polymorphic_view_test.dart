// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'dart:typed_data';
import 'package:expect/expect.dart';

final V = 5;

void runShort(view) {
  for (int i = 0; i < view.length; i++) {
    view[i] = V;
  }
}

void verifyShort(view) {
  var sum = 0;
  for (int i = 0; i < view.length; i++) {
    sum += view[i];
  }
  // 1285 * view.length.
  Expect.equals(657920, sum);
}

void testShort() {
  var int8 = new Uint8List(1024);
  var int16 = new Uint16List(512);

  var view = new Uint8List.view(int8.buffer);
  view[0] = V;

  view = new Uint8List.view(int16.buffer);
  for (int i = 0; i < 1000; i++) {
    runShort(view);
  }

  Expect.equals(1285, int16[0]);
  verifyShort(int16);
}

void runXor(view) {
  var mask = new Int32x4(0x1, 0x1, 0x1, 0x1);
  for (var i = 0; i < view.length; i++) {
    view[i] ^= mask;
  }
}

void verifyXor(view) {
  var sum = 0;
  for (var i = 0; i < view.length; i++) {
    sum += view[i];
  }
  Expect.equals(256, sum);
}

void testXor() {
  var int8 = new Uint8List(1024);
  var int32x4 = new Int32x4List.view(int8.buffer);
  Expect.equals(64, int32x4.length);
  for (var i = 0; i < 1001; i++) {
    runXor(int32x4);
  }
  Expect.equals(1, int8[0]);
  Expect.equals(0, int8[1]);
  Expect.equals(0, int8[2]);
  Expect.equals(0, int8[3]);
  verifyXor(int8);
}

void main() {
  testXor();
  testShort();
}
