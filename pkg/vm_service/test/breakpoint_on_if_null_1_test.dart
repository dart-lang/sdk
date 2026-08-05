// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_on_if_null_1_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_on_if_null_1_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .runStepThroughProgramRecordingStops()
        .checkRecordedStops()
        .run(
            testeeMain: testee_lib.main, pauseOnStart: true, pauseOnExit: true);
