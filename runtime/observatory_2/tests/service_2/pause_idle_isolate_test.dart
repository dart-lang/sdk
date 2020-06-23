// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';
import 'dart:isolate' show ReceivePort;
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

var receivePort;

void testMain() {
  receivePort = new ReceivePort();
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    print('Resuming...');
    await isolate.resume();

    // Wait for the isolate to become idle.  We detect this by querying
    // the stack until it becomes empty.
    var frameCount;
    do {
      var stack = await isolate.getStack();
      frameCount = stack['frames'].length;
      print('Frames: $frameCount');
      sleep(const Duration(milliseconds: 10));
    } while (frameCount > 0);
    print('Isolate is idle.');
    await isolate.reload();
    expect(isolate.pauseEvent is M.ResumeEvent, isTrue);

    // Make sure that the isolate receives an interrupt even when it is
    // idle. (https://github.com/dart-lang/sdk/issues/24349)
    var interruptFuture = hasPausedFor(isolate, ServiceEvent.kPauseInterrupted);
    print('Pausing...');
    await isolate.pause();
    await interruptFuture;
  },
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain,
    verbose_vm: true,
    extraArgs: ['--trace-service', '--trace-service-verbose']);
