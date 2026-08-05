// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'async_single_step_into_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('async_single_step_into_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver() // print.
        .stoppedAtLine('LINE_C')
        .stepOver() // print.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepOver() // print.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main, extraArgs: extraDebuggingArgs);
