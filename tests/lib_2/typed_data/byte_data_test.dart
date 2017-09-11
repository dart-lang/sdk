// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import "package:expect/expect.dart";

main() {
  testRegress10898();
}

testRegress10898() {
  ByteData data = new ByteData(16);
  Expect.equals(16, data.lengthInBytes);
  for (int i = 0; i < data.lengthInBytes; i++) {
    Expect.equals(0, data.getInt8(i));
    data.setInt8(i, 42 + i);
    Expect.equals(42 + i, data.getInt8(i));
  }

  ByteData backing = new ByteData(16);
  ByteData view = new ByteData.view(backing.buffer);
  for (int i = 0; i < view.lengthInBytes; i++) {
    Expect.equals(0, view.getInt8(i));
    view.setInt8(i, 87 + i);
    Expect.equals(87 + i, view.getInt8(i));
  }

  view = new ByteData.view(backing.buffer, 4);
  Expect.equals(12, view.lengthInBytes);
  for (int i = 0; i < view.lengthInBytes; i++) {
    Expect.equals(87 + i + 4, view.getInt8(i));
  }

  view = new ByteData.view(backing.buffer, 8, 4);
  Expect.equals(4, view.lengthInBytes);
  for (int i = 0; i < view.lengthInBytes; i++) {
    Expect.equals(87 + i + 8, view.getInt8(i));
  }
}
