// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoints_ignore_late_initialization_error_instructions_lib.dart'
    as testee_lib;
import 'common/service_test_common.dart';

Future<void> main([args = const <String>[]]) => IsolateTestHarness(
      'breakpoints_ignore_late_initialization_error_instructions_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .setBreakpointAtLine('LINE_C')
        .resumeProgramRecordingStops(false)
        .checkRecordedStops()
        .run(
            testeeMain: testee_lib.main, pauseOnStart: true, pauseOnExit: true);
