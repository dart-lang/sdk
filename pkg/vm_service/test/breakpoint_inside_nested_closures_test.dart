// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_inside_nested_closures_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_inside_nested_closures_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtExit()
        .run(
            testeeMain: testee_lib.main, pauseOnStart: true, pauseOnExit: true);
