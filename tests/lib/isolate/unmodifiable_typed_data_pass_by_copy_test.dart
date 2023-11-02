// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  final backing = new Uint8List(1);
  final original = backing.asUnmodifiableView();
  var port;
  port = new RawReceivePort((copy) {
    port.close();
    asyncEnd();

    Expect.isFalse(identical(original, copy));
    backing[0] = 1;
    Expect.equals(1, original[0]);
    Expect.equals(0, copy[0]);
  });

  asyncStart();
  port.sendPort.send(original);
}
