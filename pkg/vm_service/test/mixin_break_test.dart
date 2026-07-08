// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'mixin_break_lib.dart' as testee_lib;

const file = 'mixin_break/mixin_break_mixin_class.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('mixin_break_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .setBreakpointAtUriAndLine(file, 'LINE_B')
        .resumeProgramRecordingStops(true)
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: false,
          pauseOnExit: true,
        );
