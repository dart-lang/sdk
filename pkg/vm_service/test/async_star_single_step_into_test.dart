// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'async_star_single_step_into_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
        'async_star_single_step_into_lib.dart', args)
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_1')
    .stepOver() // debugger.
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_E')
    .stepOver() // print.
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_F')
    .stepInto()
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_C')
    .stepOver() // print.
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_G') // foobar()
    .stepInto()
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_G') // await for
    .stepInto()
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_A')
    // Resume here to exit the generator function.
    // TODO(johnmccutchan): Implement support for step-out of async functions.
    .resumeIsolate()
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_0')
    .stepOver() // debugger.
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_D')
    .stepOver() // print.
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_G')
    .stepInto()
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_B')
    .resumeIsolate()
    .run(testeeMain: testee_lib.main, extraArgs: extraDebuggingArgs);
