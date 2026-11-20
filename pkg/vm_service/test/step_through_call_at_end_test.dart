// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that returning from a call that is the last statement of a
// function or closure does not stop at that call again before stopping at
// the end of the function.

import 'common/service_test_common.dart';
import 'step_through_call_at_end_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('step_through_call_at_end_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C') // callMember entry.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_F') // callClosure entry.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_G') // closure declaration.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_J')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_G') // closure entry.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_H')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_L') // helper entry.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_M')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_N')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_I') // closure end, not LINE_H again.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_K') // callClosure end, not LINE_J again.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E') // callMember end, not LINE_D again.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B') // code end, not LINE_A again.
        .resumeIsolate()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
        );
