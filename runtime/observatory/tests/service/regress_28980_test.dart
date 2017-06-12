// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

const int LINE_A = 19, LINE_B = 38;

var _lock;
var _lockEnabled = true;

String flutterRoot = "abc";

foo(a, b, c, d) {
  return new A(); // LINE_A
}

class A {
  Future lock() => new Future.microtask(() => print("lock"));
  String path = "path";
}

class FileSystemException {}

Future<Null> test_code() async {
  if (!_lockEnabled) return null;
  assert(_lock == null);
  _lock = foo(flutterRoot, 'bin', 'cache', 'lockfile');
  bool locked = false;
  bool printed = false;
  while (!locked) {
    try {
      await _lock.lock();
      locked = true; // LINE_B
    } on FileSystemException {
      if (!printed) {
        print('Print path: ${_lock.path}');
        print('Just another line...');
        printed = true;
      }
      await new Future<Null>.delayed(const Duration(milliseconds: 50));
    }
  }
}

Future<Isolate> stepThroughProgram(Isolate isolate) async {
  Completer completer = new Completer();
  int pauseEventsSeen = 0;

  await subscribeToStream(isolate.vm, VM.kDebugStream,
      (ServiceEvent event) async {
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      // We are paused: Step further.
      pauseEventsSeen++;
      isolate.stepInto();
    } else if (event.kind == ServiceEvent.kPauseExit) {
      // We are at the exit: The test is done.
      expect(pauseEventsSeen > 20, true,
          reason: "Saw only $pauseEventsSeen pause events.");
      await cancelStreamSubscription(VM.kDebugStream);
      completer.complete();
    }
  });
  isolate.resume();
  return completer.future;
}

var tests = [
  hasPausedAtStart,
  markDartColonLibrariesDebuggable,
  setBreakpointAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stepInto,
  stepInto,
  stepInto,
  resumeIsolate,
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: test_code, pause_on_start: true, pause_on_exit: false);
