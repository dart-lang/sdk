// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_in_enhanced_enums_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_in_enhanced_enums_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_C')
        .setBreakpointAtLine('LINE_F')
        .setBreakpointAtLine('LINE_G')
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .setBreakpointAtLine('LINE_D')
        .setBreakpointAtLine('LINE_E')
        .setBreakpointAtLine('LINE_H')
        .resumeProgramRecordingStops(false)
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
