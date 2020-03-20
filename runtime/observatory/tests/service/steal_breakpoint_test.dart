// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--steal-breakpoints

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'dart:async';

int counter = 0;

void periodicTask(_) {
  counter++; // Line 14.  We set our breakpoint here.
  if (counter % 1000 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

var tests = <IsolateTest>[
// Add a breakpoint and wait for it to be reached.
  (Isolate isolate) async {
    await isolate.rootLibrary.load();

    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Isolate paused at breakpoint');
        subscription.cancel();
        completer.complete();
      }
    });

    // Add the breakpoint.
    var script = isolate.rootLibrary.scripts[0];
    var result = await isolate.addBreakpoint(script, 14);
    expect(result is Breakpoint, isTrue);

    await completer.future; // Wait for breakpoint event to fire.
  },

// We are at the breakpoint on line 14.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    await script.load();
    expect(script.name, endsWith('steal_breakpoint_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(14));
  },

// Resume
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        print('Isolate resumed');
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.resume();
    await completer.future;
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: startTimer);
