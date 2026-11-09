// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--gc_on_foc_slow_path

import "dart:isolate";
import "dart:typed_data";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();
  var port;
  port = new RawReceivePort((message) {
    var expando = message[0] as Expando;
    var key = message[1];
    var large = expando[key] as Uint8List;
    Expect.equals(large.length, 1 << 20);

    port.close();
    asyncEnd();
  });

  var key = new Object();
  var large = Uint8List(1 << 20);
  var expando = new Expando();
  expando[key] = large;

  port.sendPort.send([expando, key]);
}
