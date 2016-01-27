// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

testMain() {
  var foo;      // line 11
  foo = 42;     // line 12
  print(foo);
}

var tests = [
  hasPausedAtStart,

  // Add breakpoints at line 11 and line 12.
  (Isolate isolate) async {
    var rootLib = isolate.rootLibrary;
    await rootLib.load();
    var script = rootLib.scripts[0];

    var bpt1 = await isolate.addBreakpoint(script, 11);
    var bpt2 = await isolate.addBreakpoint(script, 12);
    expect(await bpt1.location.getLine(), equals(11));
    expect(await bpt2.location.getLine(), equals(12));

    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    Completer completer = new Completer();
    var subscription;
    var breakCount = 0;
    subscription = stream.listen((ServiceEvent event) async {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        breakCount++;
        print('break count is $breakCount');
        if (breakCount == 1) {
          // We are stopped at breakpoint 1.
          expect(event.breakpoint.number, equals(bpt1.number));

          // Remove both breakpoints
          var result = await isolate.removeBreakpoint(bpt1);
          expect(result.type, equals("Success"));

          result = await isolate.removeBreakpoint(bpt2);
          expect(result.type, equals("Success"));

          isolate.stepOver();
        } else {
          // No breakpoint.
          expect(event.breakpoint, isNull);

          // We expect the next step to take us to line 12.
          var stack = await isolate.getStack();
          expect(await stack['frames'][0].location.getLine(), equals(12));

          subscription.cancel();
          completer.complete(null);
        }
      }
    });
    isolate.resume();
    await completer.future;
  },
];

main(args) => runIsolateTests(args, tests,
                              testeeConcurrent: testMain,
                              pause_on_start: true);
