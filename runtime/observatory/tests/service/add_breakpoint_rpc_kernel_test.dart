// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

import 'dart:async';

const int LINE_A = 22;

int value = 0;

int incValue(int amount) {
  value += amount;
  return amount;
}

Future testMain() async {
  incValue(incValue(1)); // line A.
}

var tests = <IsolateTest>[
  hasPausedAtStart,

  (Isolate isolate) async {
    var rootLib = isolate.rootLibrary;
    await rootLib.load();
    var script = rootLib.scripts[0];

    final bpt1 = await isolate.addBreakpoint(script, LINE_A);
    expect(bpt1.number, equals(1));
    expect(bpt1.resolved, true);
    expect(await bpt1.location!.getLine(), equals(LINE_A));
    expect(await bpt1.location!.getColumn(), equals(12));

    // Breakpoint with specific column.
    final bpt2 = await isolate.addBreakpoint(script, LINE_A, 3);
    expect(bpt2.number, equals(2));
    expect(bpt2.resolved, true);
    expect(await bpt2.location!.getLine(), equals(LINE_A));
    expect(await bpt2.location!.getColumn(), equals(3));

    await isolate.resume();
    await hasStoppedAtBreakpoint(isolate);
    // The first breakpoint hits before value is modified.
    Instance result = await rootLib.evaluate('value') as Instance;
    expect(result.valueAsString, equals('0'));

    await isolate.resume();
    await hasStoppedAtBreakpoint(isolate);
    // The second breakpoint hits after value has been modified once.
    result = await rootLib.evaluate('value') as Instance;
    expect(result.valueAsString, equals('1'));

    // Remove the breakpoints.
    expect((await isolate.removeBreakpoint(bpt1)).type, equals('Success'));
    expect((await isolate.removeBreakpoint(bpt2)).type, equals('Success'));
  },

  // Test resolution of column breakpoints.
  (Isolate isolate) async {
    var script = isolate.rootLibrary.scripts[0];
    // Try all valid column arguments.
    for (int col = 1; col <= 36; col++) {
      var bpt = await isolate.addBreakpoint(script, LINE_A, col);
      expect(bpt.resolved, isTrue);
      int resolvedLine = await bpt.location!.getLine() as int;
      int resolvedCol = await bpt.location!.getColumn() as int;
      print('$LINE_A:${col} -> ${resolvedLine}:${resolvedCol}');
      if (col < 12) {
        expect(resolvedLine, equals(LINE_A));
        expect(resolvedCol, equals(3));
      } else {
        expect(resolvedLine, equals(LINE_A));
        expect(resolvedCol, equals(12));
      }
      expect((await isolate.removeBreakpoint(bpt)).type, equals('Success'));
    }

    // Ensure that an error is thrown when 0 is passed as the column argument.
    try {
      await isolate.addBreakpoint(script, LINE_A, 0);
      fail('Expected to catch a ServerRpcException');
    } on ServerRpcException catch (e) {
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message, "addBreakpoint: invalid 'column' parameter: 0");
    }

    // Ensure that an error is thrown when a number greater than the number of
    // columns on the specified line is passed as the column argument.
    try {
      await isolate.addBreakpoint(script, LINE_A, 37);
      fail('Expected to catch a ServerRpcException');
    } on ServerRpcException catch (e) {
      expect(e.code, equals(ServerRpcException.kCannotAddBreakpoint));
      expect(
        e.message,
        'addBreakpoint: Cannot add breakpoint at $LINE_A:37. Error occurred '
        'when resolving breakpoint location: No debuggable code where '
        'breakpoint was requested.',
      );
    }
  },
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true);
