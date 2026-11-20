// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that a breakpoint on a line calling debugger() is only hit once
// per execution of that line. Stepping over the call or resuming pauses in
// debugger() as well, which is not reported as a breakpoint hit. Stepping
// into the call does not pause in debugger().

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'breakpoint_at_debugger_call_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

Future<void> pausedAtBreakpoint(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  expect(isolate.pauseEvent!.pauseBreakpoints, isNotEmpty);
}

Future<void> pausedInDebuggerCall(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  expect(isolate.pauseEvent!.pauseBreakpoints, isEmpty);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_at_debugger_call_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        // First call: step over the debugger() line.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(pausedAtBreakpoint)
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(pausedInDebuggerCall)
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(pausedAtBreakpoint)
        // Second call: resume from the breakpoint on the debugger() line.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(pausedAtBreakpoint)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(pausedInDebuggerCall)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(pausedAtBreakpoint)
        // Third call: step into the debugger() call.
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(pausedAtBreakpoint)
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
        );
