// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'dart:typed_data';
import 'package:expect/expect.dart';

unalignedFloat32() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 4; i++) {
    bytes.setFloat32(i, 16.25, Endian.host);
    Expect.equals(16.25, bytes.getFloat32(i, Endian.host));
  }
}

unalignedFloat64() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 8; i++) {
    bytes.setFloat64(i, 16.25, Endian.host);
    Expect.equals(16.25, bytes.getFloat64(i, Endian.host));
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    unalignedFloat32();
    unalignedFloat64();
  }
}
