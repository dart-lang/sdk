// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  var events = [];
  StreamController controller;
  // Test multiple subscribers of an asBroadcastStream inside the same
  // `catchErrors`.
  catchErrors(() {
    var stream = new Stream.fromIterable([1, 2]).asBroadcastStream();
    stream.listen(events.add);
    stream.listen(events.add);
  }).listen((x) { events.add("outer: $x"); },
            onDone: () {
              Expect.listEquals([1, 1, 2, 2], events);
              port.close();
            });
}
