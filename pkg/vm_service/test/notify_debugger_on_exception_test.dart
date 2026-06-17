// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// See: https://github.com/flutter/flutter/issues/17007

import 'common/service_test_common.dart';
import 'notify_debugger_on_exception_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'notify_debugger_on_exception_lib.dart',
      args,
    )
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_B')
        .run(
          testeeMain: testee_lib.main,
          pauseOnUnhandledExceptions: true,
        );
