// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";

@pragma("vm:deeply-immutable")
final class Box {
  final int contents;
  const Box(this.contents);
}

main() {
  var immutable = Box(42);
  var port = new RawReceivePort();
  port.handler = (msg) {
    if (!identical(msg, immutable)) {
      throw "Not treated as immutable";
    }
    port.close();
  };
  port.sendPort.send(immutable);
}
