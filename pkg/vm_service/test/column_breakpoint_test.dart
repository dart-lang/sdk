// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'column_breakpoint_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('column_breakpoint_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLineColumn('LINE_A', 34) // on second '=' of 'i == 0'
        .setBreakpointAtLineColumn('LINE_B', 13) // on 'n' of 'b.length'
        .resumeProgramRecordingStops(false)
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
