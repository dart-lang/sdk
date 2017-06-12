// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

void testMain() {
  print('Hello');
}

var tests = [
  (Isolate isolate) async {
    print('Getting stream...');
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    print('Subscribing...');
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseStart) {
        print('Received $event');
        subscription.cancel();
        completer.complete();
      } else {
        print('Ignoring event $event');
      }
    });
    print('Subscribed.  Pause event is ${isolate.pauseEvent}');

    if (isolate.pauseEvent != null && isolate.pauseEvent is M.PauseStartEvent) {
      // Wait for the isolate to hit PauseStart.
      subscription.cancel();
      print('Subscription cancelled.');
    } else {
      print('Waiting for pause start event.');
      await completer.future;
    }
    print('Done waiting for pause event.');

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
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Received PauseBreakpoint');
        subscription.cancel();
        completer.complete();
      }
      print('Got ${event.kind}');
    });

    print('Stepping...');
    isolate.stepInto();

    // Wait for the isolate to hit PauseBreakpoint.
    print('Waiting for PauseBreakpoint');
    await completer.future;

    // Grab the timestamp.
    print('Getting pausevent timestamp');
    var pausetime2 = isolate.pauseEvent.timestamp;
    expect(pausetime2, isNotNull);
    // Reload the isolate.
    print('Reloading isolate');
    await isolate.reload();
    print('Reload finished');
    // Verify that it is the same.
    expect(pausetime2.millisecondsSinceEpoch,
        equals(isolate.pauseEvent.timestamp.millisecondsSinceEpoch));

    expect(pausetime2.millisecondsSinceEpoch,
        greaterThan(pausetime1.millisecondsSinceEpoch));

    print('Test finished');
  },
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain,
    pause_on_start: true,
    pause_on_exit: true,
    verbose_vm: true,
    extraArgs: ['--trace-service', '--trace-service-verbose']);
