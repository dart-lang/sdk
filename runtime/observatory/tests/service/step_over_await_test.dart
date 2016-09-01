// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --trace_service

import 'dart:async';
import 'dart:developer';

import 'test_helper.dart';
import 'service_test_common.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

const int LINE_A = 25;
const int LINE_B = 27;
const int LINE_C = 29;
const int LINE_D = 30;

// This tests the low level synthetic breakpoint added / paused / removed
// machinery triggered by the step OverAwait command.
asyncWithoutAwait() async {
  debugger();
  print('a');  // LINE_A
  await new Future.delayed(new Duration(seconds: 2));
  print('b');  // LINE_B
  debugger();  // LINE_C
  debugger();  // LINE_D
}

testMain() {
  asyncWithoutAwait();
}

Breakpoint syntheticBreakpoint;

Future<Isolate> testLowLevelAwaitOver(
    Isolate isolate) {
  assert(M.isAtAsyncSuspension(isolate.pauseEvent));

  int state = 0;
  bool firstResume = true;
  handleBreakpointAdded(ServiceEvent event) {
    expect(syntheticBreakpoint, isNull);
    expect(state, 0);
    if (!event.breakpoint.isSyntheticAsyncContinuation) {
      // Not a synthetic async breakpoint.
      return;
    }
    if (event.owner != isolate) {
      // Wrong isolate.
      return;
    }
    syntheticBreakpoint = event.breakpoint;
    print('!!!! Synthetic async breakpoint added ${syntheticBreakpoint}');
    state = 1;
  }

  handleResume(ServiceEvent event) {
    if (firstResume) {
      expect(state, 1);
      if (event.owner != isolate) {
        // Wrong isolate.
        return;
      }
      print('!!!! Got first resume.');
      state = 2;
      firstResume = false;
    } else {
      expect(state, 3);
      if (event.owner != isolate) {
        // Wrong isolate.
        return;
      }
      print('!!!! Got second resume.');
      state = 4;
    }

  }

  handlePauseBreakpoint(ServiceEvent event) {
    expect(syntheticBreakpoint, isNotNull);
    expect(state, 2);
    if (!event.breakpoint.isSyntheticAsyncContinuation) {
      // Not a synthetic async breakpoint.
      return;
    }
    if (event.owner != isolate) {
      // Wrong isolate.
      return;
    }
    expect(event.breakpoint, equals(syntheticBreakpoint));
    print('!!!! Paused at synthetic async breakpoint ${syntheticBreakpoint}');
    state = 3;
  }

  handleBreakpointRemoved(ServiceEvent event) {
    expect(syntheticBreakpoint, isNotNull);
    expect(state, 4);
    if (!event.breakpoint.isSyntheticAsyncContinuation) {
      // Not a synthetic async breakpoint.
      return;
    }
    if (event.owner != isolate) {
      // Wrong isolate.
      return;
    }
    expect(event.breakpoint, equals(syntheticBreakpoint));
    print('!!!! Synthetic async breakpoint removed ${syntheticBreakpoint}');
    state = 5;
    syntheticBreakpoint = null;
  }

  // Set up a listener to wait for debugger events.
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) async {
      if (event.kind == ServiceEvent.kBreakpointAdded) {
        handleBreakpointAdded(event);
        expect(state, 1);
      } else if (event.kind == ServiceEvent.kResume) {
        if (firstResume) {
          handleResume(event);
          expect(state, 2);
        } else {
          handleResume(event);
          expect(state, 4);
        }
      } else if (event.kind == ServiceEvent.kPauseBreakpoint) {
        handlePauseBreakpoint(event);
        expect(state, 3);
        // Check that we are paused after the await statement.
        await (stoppedAtLine(LINE_B)(isolate));
        // Resume the isolate so that we trigger the breakpoint removal.
        print('!!!! Triggering synthetic breakpoint removal.');
        isolate.resume();
      } else if (event.kind == ServiceEvent.kBreakpointRemoved) {
        handleBreakpointRemoved(event);
        expect(state, 5);
        subscription.cancel();
        if (completer != null) {
          // Reload to update isolate.pauseEvent.
          completer.complete(isolate.reload());
          completer = null;
        }
      }
    });
  });

  isolate.stepOverAsyncSuspension();

  return completer.future;  // Will complete when breakpoint added.
}


var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,
  stepOver,
  stepOver,
  (Isolate isolate) async {
    expect(M.isAtAsyncSuspension(isolate.pauseEvent), isTrue);
    expect(syntheticBreakpoint, isNull);
  },
  testLowLevelAwaitOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
