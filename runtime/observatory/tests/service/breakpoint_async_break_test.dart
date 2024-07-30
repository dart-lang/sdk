// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:async';

const int LINE = 17;

// Issue: https://github.com/dart-lang/sdk/issues/36622
Future<void> testMain() async {
  for (int i = 0; i < 2; i++) {
    if (i > 0) {
      break; // breakpoint here
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    var rootLib = isolate.rootLibrary;
    await rootLib.load();
    var script = rootLib.scripts[0];

    // Future breakpoint.
    var bpt = await isolate.addBreakpoint(script, LINE);
    expect(bpt.number, 1);
    expect(bpt.resolved, isTrue);
    expect(await bpt.location!.getLine(), LINE);
    expect(await bpt.location!.getColumn(), 7);

    await isolate.resume();
    await hasStoppedAtBreakpoint(isolate);

    // Remove the breakpoints.
    expect((await isolate.removeBreakpoint(bpt)).type, 'Success');
  },
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true);
