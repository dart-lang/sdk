// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_on_simple_conditions_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_on_simple_conditions_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .setBreakpointAtLine('LINE_C')
        .setBreakpointAtLine('LINE_D')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main, pauseOnStart: true);
