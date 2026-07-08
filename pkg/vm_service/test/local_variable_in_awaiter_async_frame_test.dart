// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'local_variable_in_awaiter_async_frame_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('local_variable_in_awaiter_async_frame_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .hasLocalVarInTopStackFrame('caption')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .hasLocalVarInTopStackFrame('caption')
        .hasLocalVarInTopStackFrame('caption')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
