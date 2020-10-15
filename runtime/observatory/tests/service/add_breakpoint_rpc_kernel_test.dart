// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

import 'dart:async';

const int LINE_A = 23;
const int LINE_B = 25;

int value = 0;

int incValue(int amount) {
  value += amount;
  return amount;
}

Future testMain() async {
  incValue(incValue(1)); // line A.

  incValue(incValue(1)); // line B.
}

var tests = <IsolateTest>[
  hasPausedAtStart,

  // Test future breakpoints.
  (Isolate isolate) async {
    var rootLib = isolate.rootLibrary;
    await rootLib.load();
    var script = rootLib.scripts[0];

    // Future breakpoint.
    var futureBpt1 = await isolate.addBreakpoint(script, LINE_A);
    expect(futureBpt1.number, equals(1));
    expect(futureBpt1.resolved, isFalse);
    expect(await futureBpt1.location!.getLine(), equals(LINE_A));
    expect(await futureBpt1.location!.getColumn(), equals(null));

    // Future breakpoint with specific column.
    var futureBpt2 = await isolate.addBreakpoint(script, LINE_A, 3);
    expect(futureBpt2.number, equals(2));
    expect(futureBpt2.resolved, isFalse);
    expect(await futureBpt2.location!.getLine(), equals(LINE_A));
    expect(await futureBpt2.location!.getColumn(), equals(3));

    int resolvedCount =
        await resumeAndCountResolvedBreakpointsUntilPause(isolate);

    // After resolution the breakpoints have assigned line & column.
    expect(resolvedCount, equals(2));
    expect(futureBpt1.resolved, isTrue);
    expect(await futureBpt1.location!.getLine(), equals(LINE_A));
    expect(await futureBpt1.location!.getColumn(), equals(12));
    expect(futureBpt2.resolved, isTrue);
    expect(await futureBpt2.location!.getLine(), equals(LINE_A));
    expect(await futureBpt2.location!.getColumn(), equals(3));

    // The first breakpoint hits before value is modified.
    Instance result = await rootLib.evaluate('value') as Instance;
    expect(result.valueAsString, equals('0'));

    isolate.resume();
    await hasStoppedAtBreakpoint(isolate);

    // The second breakpoint hits after value has been modified once.
    result = await rootLib.evaluate('value') as Instance;
    expect(result.valueAsString, equals('1'));

    // Remove the breakpoints.
    expect(
        (await isolate.removeBreakpoint(futureBpt1)).type, equals('Success'));
    expect(
        (await isolate.removeBreakpoint(futureBpt2)).type, equals('Success'));
  },

  // Test resolution of column breakpoints.
  (Isolate isolate) async {
    var script = isolate.rootLibrary.scripts[0];
    // Try all columns, including some columns that are too big.
    for (int col = 1; col <= 50; col++) {
      var bpt = await isolate.addBreakpoint(script, LINE_A, col);
      expect(bpt.resolved, isTrue);
      int resolvedLine = await bpt.location!.getLine() as int;
      int resolvedCol = await bpt.location!.getColumn() as int;
      print('$LINE_A:${col} -> ${resolvedLine}:${resolvedCol}');
      if (col <= 12) {
        expect(resolvedLine, equals(LINE_A));
        expect(resolvedCol, equals(3));
      } else if (col <= 36) {
        expect(resolvedLine, equals(LINE_A));
        expect(resolvedCol, equals(12));
      } else {
        expect(resolvedLine, equals(LINE_B));
        expect(resolvedCol, equals(12));
      }
      expect((await isolate.removeBreakpoint(bpt)).type, equals('Success'));
    }

    // Make sure that a zero column is an error.
    var caughtException = false;
    try {
      await isolate.addBreakpoint(script, 20, 0);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message, "addBreakpoint: invalid 'column' parameter: 0");
    }
    expect(caughtException, isTrue);
  },
];

Future<int> resumeAndCountResolvedBreakpointsUntilPause(Isolate isolate) async {
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  Completer completer = new Completer();
  var subscription;
  int resolvedCount = 0;
  subscription = stream.listen((ServiceEvent event) async {
    if (event.kind == ServiceEvent.kBreakpointResolved) {
      resolvedCount++;
    }
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      subscription.cancel();
      completer.complete();
    }
  });
  await isolate.resume();
  await completer.future;
  return resolvedCount;
}

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true);
