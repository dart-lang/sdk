// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

int counter = 0;

void funcB() {
  counter++;  // line 13
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

var tests = [

// Go to breakpoint at line 13.
(Isolate isolate) {
  return isolate.rootLib.load().then((_) {
      // Set up a listener to wait for breakpoint events.
      Completer completer = new Completer();
      List events = [];
      isolate.vm.events.stream.listen((ServiceEvent event) {
        if (event.eventType == 'BreakpointReached') {
          print('Breakpoint reached');
          completer.complete();
        }
      });

      // Add the breakpoint.
      var script = isolate.rootLib.scripts[0];
      var line = 13;
      return isolate.addBreakpoint(script, line).then((ServiceObject bpt) {
          return completer.future;  // Wait for breakpoint reached.
      });
    });
},

// Inspect code objects for top two frames.
(Isolate isolate) {
  return isolate.getStack().then((ServiceMap stack) {
      // Make sure we are in the right place.
      expect(stack.type, equals('Stack'));
      expect(stack['frames'].length, greaterThanOrEqualTo(3));
      var frame0 = stack['frames'][0];
      var frame1 = stack['frames'][1];
      print(frame0);
      expect(frame0['function'].name, equals('funcB'));
      expect(frame1['function'].name, equals('funcA'));
      var codeId0 = frame0['code'].id;
      var codeId1 = frame1['code'].id;

      List tests = [];
      // Load code from frame 0.
      tests.add(isolate.get(codeId0)..then((Code code) {
            expect(code.type, equals('Code'));
            expect(code.function.name, equals('funcB'));
            expect(code.hasDisassembly, equals(true));
          }));
      // Load code from frame 0.
      tests.add(isolate.get(codeId1)..then((Code code) {
            expect(code.type, equals('Code'));
            expect(code.function.name, equals('funcA'));
            expect(code.hasDisassembly, equals(true));
          }));
      return Future.wait(tests);
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
