// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'step_through_patterns_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('step_through_patterns_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .runStepThroughProgramRecordingStops()
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          extraArgs: extraDebuggingArgs,
          pauseOnStart: true,
          pauseOnExit: true,
        );
