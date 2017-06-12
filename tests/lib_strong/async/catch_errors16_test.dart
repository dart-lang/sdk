// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  var events = [];
  StreamController controller = new StreamController();
  Stream stream = controller.stream;
  // Test that the subscription of a stream is what counts. The error (2) runs
  // through the map-stream which goes through the nested `catchError` but
  // the nested `catchError` won't see the error.
  catchErrors(() {
    stream = stream.map((x) => x + 100);
  }).listen((x) {
    events.add(x);
  });
  stream
      .transform(new StreamTransformer.fromHandlers(handleError: (e, st, sink) {
    sink.add("error $e");
  })).listen((x) {
    events.add("stream $x");
  }, onDone: () {
    Expect.listEquals([
      "stream 101",
      "stream error 2",
    ], events);
    asyncEnd();
  });
  controller.add(1);
  controller.addError(2);
  controller.close();
}
