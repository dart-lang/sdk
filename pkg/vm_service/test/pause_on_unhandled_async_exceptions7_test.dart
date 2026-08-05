// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'common/service_test_common.dart';
import 'pause_on_unhandled_async_exceptions7_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'pause_on_unhandled_async_exceptions7_lib.dart',
      args,
    )
        .addCustomTest(
          expectUnhandledExceptionWithFrames(
            exceptionAsString: 'LastUncaughtException',
          ),
        )
        .run(
          testeeMain: testee_lib.main,
          pauseOnUnhandledExceptions: true,
        );
