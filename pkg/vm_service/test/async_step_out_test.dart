// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'async_step_out_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'async_step_out_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver() // debugger.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .stepOver() // print.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .asyncNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .stepOver() // print.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .stepOut() // out of helper to awaiter testMain.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_F')
        .run(
          testeeMain: testee_lib.main,
          extraArgs: extraDebuggingArgs,
        );
