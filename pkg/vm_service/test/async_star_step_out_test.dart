// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'async_star_step_out_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('async_star_step_out_lib.dart', args)
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
        .stoppedAtLine('LINE_H') // foobar().
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_H') // await for.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepOut() // step out of generator.
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_H', column: 46) // on '{'
        .stepInto()
        .hasStoppedAtBreakpoint() // debugger().
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D') // print.
        .stepInto()
        .hasStoppedAtBreakpoint() // await for.
        .stepInto()
        .hasStoppedAtBreakpoint() // back in generator.
        .stoppedAtLine('LINE_B')
        .stepOut() // step out of generator.
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_H', column: 46) // on '{'
        .stepInto()
        .hasStoppedAtBreakpoint() // debugger().
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D') // print.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_H') // await for.
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stepOut() // step out of generator.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_I') // return null.
        .run(testeeMain: testee_lib.main, extraArgs: extraDebuggingArgs);
