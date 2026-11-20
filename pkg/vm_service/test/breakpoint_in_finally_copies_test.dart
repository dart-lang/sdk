// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that a breakpoint in a finally block is hit on every path through
// it. Compiled code has a copy of the finally block for each way of leaving
// the try block, here for the break, for completing normally and for an
// exception, and copies with the same source positions can be adjacent.
//
// The breakpoint after the loop ensures that a missed breakpoint in the loop
// fails the test instead of letting the testee exit.

import 'breakpoint_in_finally_copies_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_in_finally_copies_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        // First iteration, which completes normally.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Second iteration, which completes normally.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Third iteration, which throws an exception.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
        );
