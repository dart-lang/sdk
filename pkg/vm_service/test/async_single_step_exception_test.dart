// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'async_single_step_exception_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'async_single_step_exception_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0') // debugger
        .stepOver()
        .stoppedAtLine('LINE_C') // print mmmm
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D') // await helper
        .stepInto()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A') // print helper
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B') // throw a
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D') // await helper (weird dispatching)
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E') // print(error)
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E') // print(error) (weird finally dispatching)
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_F') // print(foo)
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_G') // print(z)
        .resumeIsolate()
        .run(
          testeeMain: testee_lib.main,
          extraArgs: extraDebuggingArgs,
        );
