// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

const bool isJS = identical(1, 1.0);

main() {
  checkBytes(Int8List.fromList, [42]);
  checkBytes(Uint8List.fromList, [42]);
  checkBytes(Uint8ClampedList.fromList, [42]);
  checkBytes(Int16List.fromList, [42, 0]);
  checkBytes(Uint16List.fromList, [42, 0]);
  checkBytes(Int32List.fromList, [42, 0, 0, 0]);
  checkBytes(Uint32List.fromList, [42, 0, 0, 0]);
  if (!isJS) {
    checkBytes(Int64List.fromList, [42, 0, 0, 0, 0, 0, 0, 0]);
    checkBytes(Uint64List.fromList, [42, 0, 0, 0, 0, 0, 0, 0]);
  }
}

void checkBytes(dynamic Function(List<int>) makeList, List<int> expected) {
  ByteBuffer buffer = makeList([42]).buffer;
  Expect.listEquals(expected, buffer.toJS.toDart.asUint8List());
}
