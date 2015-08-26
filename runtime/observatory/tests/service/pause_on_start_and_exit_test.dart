// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

void testMain() {
  print('Hello');
}

var tests = [

(Isolate isolate) async {
  Completer completer = new Completer();
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var subscription;
  subscription = stream.listen((ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseStart) {
      print('Received PauseStart');
      subscription.cancel();
      completer.complete();
    }
  });

  if (isolate.pauseEvent != null &&
      isolate.pauseEvent.kind == ServiceEvent.kPauseStart) {
    // Wait for the isolate to hit PauseStart.
    subscription.cancel();
  } else {
    await completer.future;
  }

  // Grab the timestamp.
  var pausetime1 = isolate.pauseEvent.timestamp;
  expect(pausetime1, isNotNull);
  // Reload the isolate.
  await isolate.reload();
  // Verify that it is the same.
  expect(pausetime1.millisecondsSinceEpoch,
         equals(isolate.pauseEvent.timestamp.millisecondsSinceEpoch));

  completer = new Completer();
  stream = await isolate.vm.getEventStream(VM.kDebugStream);
  subscription = stream.listen((ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseExit) {
      print('Received PauseExit');
      subscription.cancel();
      completer.complete();
    }
  });

  print('Resuming...');
  isolate.resume();

  // Wait for the isolate to hit PauseExit.
  await completer.future;

  // Grab the timestamp.
  var pausetime2 = isolate.pauseEvent.timestamp;
  expect(pausetime2, isNotNull);
  // Reload the isolate.
  await isolate.reload();
  // Verify that it is the same.
  expect(pausetime2.millisecondsSinceEpoch,
         equals(isolate.pauseEvent.timestamp.millisecondsSinceEpoch));
  expect(pausetime2.millisecondsSinceEpoch,
         greaterThan(pausetime1.millisecondsSinceEpoch));
},

];

main(args) => runIsolateTests(args, tests,
                              testeeConcurrent: testMain,
                              pause_on_start: true, pause_on_exit: true);
