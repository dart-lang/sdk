// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/46793

// @dart = 2.9

import "dart:async";
import "dart:isolate";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();
  var port;
  port = new RawReceivePort((message) {
    print("Receive $message");

    var int32x4 = message[0] as Int32x4;
    Expect.equals(-1, int32x4.x);
    Expect.equals(0, int32x4.y);
    Expect.equals(1, int32x4.z);
    Expect.equals(2, int32x4.w);

    var float32x4 = message[1] as Float32x4;
    Expect.equals(-2.5, float32x4.x);
    Expect.equals(0.0, float32x4.y);
    Expect.equals(1.25, float32x4.z);
    Expect.equals(2.125, float32x4.w);

    var float64x2 = message[2] as Float64x2;
    Expect.equals(16.5, float64x2.x);
    Expect.equals(-32.25, float64x2.y);

    port.close();
    asyncEnd();
  });


  var list = [
    new Int32x4(-1, 0, 1, 2),
    new Float32x4(-2.5, 0.0, 1.25, 2.125),
    new Float64x2(16.5, -32.25),
  ];
  print("Send $list");
  port.sendPort.send(list);
}
