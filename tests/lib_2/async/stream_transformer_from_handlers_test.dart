// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'event_helper.dart';

get currentStackTrace {
  try {
    throw 0;
  } catch (e, st) {
    return st;
  }
}

// In most cases the callback will be 'asyncEnd'. Errors are reported
// asynchronously. We want to give them time to surface before reporting
// asynchronous tests as done.
void delayCycles(callback, int nbCycles) {
  if (nbCycles == 0) {
    callback();
    return;
  }
  Timer.run(() {
    delayCycles(callback, nbCycles - 1);
  });
}

main() {
  // Make sure the generic types are correct.
  asyncStart();
  var stackTrace = currentStackTrace;
  var events = [];
  var controller;
  controller = new StreamController<int>(onListen: () {
    controller.add(499);
    controller.addError(42, stackTrace);
    controller.close();
  });
  controller.stream
      .transform(new StreamTransformer<int, String>.fromHandlers(
          handleData: (int data, EventSink<String> sink) {
    sink.add(data.toString());
  }, handleError: (e, st, EventSink<String> sink) {
    sink.add(e.toString());
    sink.addError(e, st);
  }, handleDone: (EventSink<String> sink) {
    sink.add("done");
    sink.close();
  }))
      .listen((data) => events.add(data), onError: (e, st) {
    events.add(e);
    events.add(st);
  }, onDone: () {
    Expect.listEquals(["499", "42", 42, stackTrace, "done"], events);
    delayCycles(asyncEnd, 3);
  });
}
