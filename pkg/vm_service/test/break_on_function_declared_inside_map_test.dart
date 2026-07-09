// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'break_on_function_declared_inside_map_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'break_on_function_declared_inside_map_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .setBreakpointAtLineColumn('LINE_A', 12) // on ')' of '()'
        .setBreakpointAtLine('LINE_B')
        .resumeProgramRecordingStops(false)
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
