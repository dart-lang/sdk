// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:typed_data";
import "package:expect/expect.dart";

main() {
  for (var copying in [true, false]) {
    var b;
    testLength(n) {
      Expect.equals(n, b.length);
      if (n == 0) {
        Expect.isTrue(b.isEmpty, "isEmpty: #${b.length}");
        Expect.isFalse(b.isNotEmpty, "isNotEmpty: #${b.length}");
      } else {
        Expect.isTrue(b.isNotEmpty, "isNotEmpty: #${b.length}");
        Expect.isFalse(b.isEmpty, "isEmpty: #${b.length}");
      }
    }

    b = new BytesBuilder(copy: copying);
    testLength(0);

    b.addByte(0);
    testLength(1);

    b.add([1, 2, 3]);
    testLength(4);

    b.add(<int>[4, 5, 6]);
    testLength(7);

    b.add(new Uint8List.fromList([7, 8, 9]));
    testLength(10);

    b.add(new Uint16List.fromList([10, 11, 12]));
    testLength(13);

    var bytes = b.toBytes();
    Expect.isTrue(bytes is Uint8List);
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], bytes);
    testLength(13);

    b.add("\x0d\x0e\x0f".codeUnits);
    testLength(16);

    bytes = b.takeBytes();
    testLength(0);
    Expect.isTrue(bytes is Uint8List);
    Expect.listEquals(
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], bytes);

    b.addByte(0);
    testLength(1);

    b.clear();
    testLength(0);

    b.addByte(0);
    testLength(1);
  }
}
