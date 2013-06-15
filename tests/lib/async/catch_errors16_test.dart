// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';
import 'catch_errors.dart';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  var events = [];
  StreamController controller = new StreamController();
  Stream stream = controller.stream;
  // Test that the subscription of a stream is what counts. The error (2) runs
  // through the map-stream which goes through the nested `catchError` but
  // the nested `catchError` won't see the error.
  catchErrors(() {
    stream = stream.map((x) => x + 100);
  }).listen((x) { events.add(x); });
  stream
    .transform(new StreamTransformer(
        handleError: (e, sink) => sink.add("error $e")))
    .listen((x) { events.add("stream $x"); },
            onDone: () {
              Expect.listEquals(["stream 101",
                                "stream error 2",
                                ],
                                events);
              port.close();
            });
  controller.add(1);
  controller.addError(2);
  controller.close();
}
