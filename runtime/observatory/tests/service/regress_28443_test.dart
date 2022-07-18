// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

const int LINE_A = 28, LINE_B = 33, LINE_C = 37;

class VMServiceClient {
  VMServiceClient(this.x);
  close() => new Future.microtask(() => print("close"));
  var x;
}

collect() async {
  var uri = "abc";
  var vmService;
  await new Future.microtask(() async {
    try {
      vmService = new VMServiceClient(uri);
      await new Future.microtask(() => throw new TimeoutException("here"));
    } on dynamic {
      vmService.close();
      rethrow; // LINE_A
    }
  });
}

test_code() async /* LINE_B */ {
  try {
    await collect();
  } on TimeoutException {
    print("ok"); // LINE_C
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  markDartColonLibrariesDebuggable,
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  setBreakpointAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  setBreakpointAtLine(LINE_C),
  stepOut,
  resumeIsolate,
  stoppedAtLine(LINE_C),
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: test_code, pause_on_start: true, pause_on_exit: false);
