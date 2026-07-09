// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_in_package_parts_class_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

const String breakpointFile = 'package:test_package/the_part.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_in_package_parts_class_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtUriAndLine(breakpointFile, 'LINE_A')
        .runStepThroughProgramRecordingStops()
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
