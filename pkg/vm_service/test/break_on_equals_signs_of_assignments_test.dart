// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'break_on_equals_signs_of_assignments_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

Future<void> main([args = const <String>[]]) =>
    IsolateTestHarness('break_on_equals_signs_of_assignments_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .setBreakpointAtLine('LINE_C')
        .setBreakpointAtLine('LINE_D')
        .setBreakpointAtLine('LINE_E')
        .setBreakpointAtLine('LINE_F')
        .setBreakpointAtLine('LINE_G')
        .resumeProgramRecordingStops(false)
        .checkRecordedStops()
        .run(
            testeeMain: testee_lib.main, pauseOnStart: true, pauseOnExit: true);
