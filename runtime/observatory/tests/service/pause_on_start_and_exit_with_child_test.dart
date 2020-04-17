// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:isolate' as isolate;

void child(message) {
  print("Child got initial message");
  message.send(null);
}

void testMain() {
  var port = new isolate.RawReceivePort();
  port.handler = (message) {
    print("Parent got response");
    port.close();
  };

  isolate.Isolate.spawn(child, port.sendPort);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    VM vm = isolate.vm;

    print('Getting stream...');
    Completer completer = new Completer();
    var stream = await vm.getEventStream(VM.kDebugStream);
    print('Subscribing...');
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.isolate == isolate && event.kind == ServiceEvent.kPauseStart) {
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

    expect(isolate.pauseEvent, isNotNull);
    expect(isolate.pauseEvent is M.PauseStartEvent, isTrue);

    print("Disabling pause_isolates_on_start");
    var params = {
      'name': 'pause_isolates_on_start',
      'value': 'false',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));

    print("Disabling pause_isolates_on_exit");
    params = {
      'name': 'pause_isolates_on_exit',
      'value': 'false',
    };
    result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));

    completer = new Completer();
    stream = await vm.getEventStream(VM.kDebugStream);
    subscription = stream.listen((ServiceEvent event) {
      if (event.isolate == isolate && event.kind == ServiceEvent.kPauseExit) {
        print('Received PauseExit');
        subscription.cancel();
        completer.complete();
      }
    });

    print('Resuming at start...');
    isolate.resume();

    // Wait for the isolate to hit PauseExit.
    await completer.future;

    expect(isolate.pauseEvent, isNotNull);
    expect(isolate.pauseEvent is M.PauseExitEvent, isTrue);

    print('Resuming at exit...');
    isolate.resume();

    // Nothing else keeping the VM around. In particular, the child isolate
    // won't pause on exit.
    await vm.onDisconnect;
  },
];

main(args) => runIsolateTests(
      args, tests,
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
      verbose_vm: true,
      extraArgs: [
        '--trace-service',
        '--trace-service-verbose',
      ],
      // TODO(bkonyi): investigate failure.
      enableDds: false,
    );
