// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate' show ReceivePort;

var receivePort;

void testMain() {
  receivePort = new ReceivePort();
}

var tests = [

(Isolate isolate) async {
  Completer completer = new Completer();
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var subscription;
  subscription = stream.listen((ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseStart) {
      print('Received $event');
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
  print('Done waiting for pause event.');

  // Wait for the isolate to pause due to interruption.
  completer = new Completer();
  stream = await isolate.vm.getEventStream(VM.kDebugStream);
  bool receivedInterrupt = false;
  subscription = stream.listen((ServiceEvent event) {
    print('Received $event');
    if (event.kind == ServiceEvent.kPauseInterrupted) {
      receivedInterrupt = true;
      subscription.cancel();
      completer.complete();
    }
  });

  await isolate.resume();

  // Wait for the isolate to become idle.  We detect this by querying
  // the stack until it becomes empty.
  var frameCount;
  do {
    var stack = await isolate.getStack();
    frameCount = stack['frames'].length;
    print('frames: $frameCount');
    sleep(const Duration(milliseconds:10));
  } while (frameCount > 0);

  // Make sure that the isolate receives an interrupt even when it is
  // idle. (https://github.com/dart-lang/sdk/issues/24349)
  await isolate.pause();
  await completer.future;
  expect(receivedInterrupt, isTrue);
},

];

main(args) => runIsolateTests(args, tests,
                              testeeConcurrent: testMain,
                              pause_on_start: true,
                              trace_service: true,
                              verbose_vm: true);
