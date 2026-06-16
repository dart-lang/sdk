// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/59730: make
// sure that awaiter stack is correctly reconstructed for `FutureIterable`
// and `FutureRecordN` wait extensions.

import 'common/service_test_common.dart';
import 'pause_on_unhandled_exceptions_future_extensions_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'pause_on_unhandled_exceptions_future_extensions_lib.dart',
      args,
    )
        // We shouldn't get any debugger breaks before exit as all exceptions are
        // caught.
        .hasStoppedAtExit()
        .run(
          testeeMain: testee_lib.main,
          pauseOnUnhandledExceptions: true,
          pauseOnExit: true,
        );
