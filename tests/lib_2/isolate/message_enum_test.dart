// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import "dart:isolate";

enum Foo { BAR, BAZ }

main() {
  var p;
  p = new RawReceivePort((map) {
    Expect.equals(1, map.keys.length);
    Expect.equals(42, map.values.first);
    var key = map.keys.first;
    Expect.equals(42, map[key]);
    p.close();
  });
  asyncStart();
  Isolate.spawn(sendIt, p.sendPort).whenComplete(asyncEnd);
}

void sendIt(port) {
  var map = {Foo.BAR: 42};
  port.send(map);
}
