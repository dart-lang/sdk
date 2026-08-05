// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'notify_debugger_on_exception_yielding_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'notify_debugger_on_exception_yielding_lib.dart',
      args,
    )
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_C')
        .run(testeeMain: testee_lib.main, pauseOnUnhandledExceptions: true);
