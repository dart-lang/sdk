// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler's load elimination phase sees interfering writes to
// the array's buffer.

import "dart:typed_data";
import 'package:expect/expect.dart';

aliasWithByteData1() {
  var aa = new Int8List(10);
  var b = new ByteData.view(aa.buffer);
  for (int i = 0; i < aa.length; i++) aa[i] = 9;

  var x1 = aa[3];
  b.setInt8(3, 1);
  var x2 = aa[3];

  Expect.equals(9, x1);
  Expect.equals(1, x2);
}

aliasWithByteData2() {
  var b = new ByteData(10);
  var aa = new Int8List.view(b.buffer);
  for (int i = 0; i < aa.length; i++) aa[i] = 9;

  var x1 = aa[3];
  b.setInt8(3, 1);
  var x2 = aa[3];

  Expect.equals(9, x1);
  Expect.equals(1, x2);
}

alias8x8() {
  var buffer = new Int8List(10).buffer;
  var a1 = new Int8List.view(buffer);
  var a2 = new Int8List.view(buffer, 1);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Different indexes that alias.
  var x1 = a1[1];
  a2[0] = 0;
  var x2 = a1[1];
  Expect.equals(9, x1);
  Expect.equals(0, x2);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Same indexes that don't alias.
  x1 = a1[1];
  a2[1] = 5;
  x2 = a1[1];
  Expect.equals(9, x1);
  Expect.equals(9, x2);
}

alias8x16() {
  var a1 = new Int8List(10);
  var a2 = new Int16List.view(a1.buffer);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Same indexes that alias.
  var x1 = a1[0];
  a2[0] = 0x101;
  var x2 = a1[0];
  Expect.equals(9, x1);
  Expect.equals(1, x2);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Different indexes that alias.
  x1 = a1[4];
  a2[2] = 0x505;
  x2 = a1[4];
  Expect.equals(9, x1);
  Expect.equals(5, x2);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Same indexes that don't alias.
  x1 = a1[3];
  a2[3] = 0x505;
  x2 = a1[3];
  Expect.equals(9, x1);
  Expect.equals(9, x2);

  for (int i = 0; i < a1.length; i++) a1[i] = 9;

  // Different indexes don't alias.
  x1 = a1[2];
  a2[0] = 0x505;
  x2 = a1[2];
  Expect.equals(9, x1);
  Expect.equals(9, x2);
}

main() {
  aliasWithByteData1();
  aliasWithByteData2();
  alias8x8();
  alias8x16();
}
