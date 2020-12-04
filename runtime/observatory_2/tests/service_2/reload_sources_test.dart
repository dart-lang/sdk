// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'dart:developer';
import 'service_test_common.dart';

testMain() {
  debugger(); // Stop here.
  print('1');
  while (true) {}
}

var tests = <IsolateTest>[
  // Stopped at 'debugger' statement.
  hasStoppedAtBreakpoint,
  // Reload sources and request to pause post reload. The pause request will be
  // ignored because we are already paused at a breakpoint.
  reloadSources(true),
  // Ensure that we are still stopped at a breakpoint.
  hasStoppedAtBreakpoint,
  // Resume the isolate into the while loop.
  resumeIsolate,
  // Reload sources and request to pause post reload. The pause request will
  // be respected because we are not already paused.
  reloadSources(true),
  // Ensure that we are paused post reload request.
  hasStoppedPostRequest,
  // Resume the isolate.
  resumeIsolate,
  // Verify that it is running.
  isolateIsRunning,
  // Reload sources and do not request to pause post reload.
  reloadSources(false),
  // Verify that it is running.
  isolateIsRunning,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
