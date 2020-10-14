// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'dart:async';

int counter = 0;

void funcB() {
  counter++; // line 13
  if (counter % 100000000 == 0) {
    print(counter);
  }
}

void funcA() {
  funcB();
}

void testFunction() {
  while (true) {
    funcA();
  }
}

var tests = <IsolateTest>[
// Go to breakpoint at line 13.
  (Isolate isolate) async {
    await isolate.rootLibrary.load();
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
      var subscription;
      subscription = stream.listen((ServiceEvent event) {
        if (event.kind == ServiceEvent.kPauseBreakpoint) {
          print('Breakpoint reached');
          subscription.cancel();
          completer.complete();
        }
      });
    });

    // Add the breakpoint.
    var script = isolate.rootLibrary.scripts[0];
    var line = 13;
    isolate.addBreakpoint(script, line);
    await completer.future; // Wait for breakpoint reached.
  },

// Inspect code objects for top two frames.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(3));
    var frame0 = stack['frames'][0];
    var frame1 = stack['frames'][1];
    print(frame0);
    expect(frame0.function.name, equals('funcB'));
    expect(frame1.function.name, equals('funcA'));
    var codeId0 = frame0.code.id;
    var codeId1 = frame1.code.id;

    List tests = <IsolateTest>[];
    // Load code from frame 0.
    Code code = await isolate.getObject(codeId0) as Code;
    expect(code.type, equals('Code'));
    expect(code.function!.name, equals('funcB'));
    expect(code.hasDisassembly, equals(true));

    // Load code from frame 0.
    code = await isolate.getObject(codeId1) as Code;
    expect(code.type, equals('Code'));
    expect(code.function!.name, equals('funcA'));
    expect(code.hasDisassembly, equals(true));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
