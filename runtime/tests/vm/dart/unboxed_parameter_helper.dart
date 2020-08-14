// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

@pragma('vm:never-inline')
double getDoubleWithHeapObjectTag() {
  final bd = ByteData(8);
  bd.setUint64(0, 0x8000000180000001, Endian.host);
  final double v = bd.getFloat64(0, Endian.host);
  return v;
}

// Make an integer that would look like an object pointer (irrespective of
// we compile to 32-bit or 64-bit and whether we use little or big endian
// encoding of the integer).
int get integerFieldValue =>
    int.parse('1') == 1 ? constIntegerFieldValue : 0x8000900180009001;
const int constIntegerFieldValue = 0x8000000180000001;
