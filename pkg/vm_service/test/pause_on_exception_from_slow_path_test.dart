// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deterministic --optimization-counter-threshold=1000

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'pause_on_exception_from_slow_path_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'pause_on_exception_from_slow_path_lib.dart',
      args,
    ).hasStoppedWithUnhandledException().run(
          testeeMain: testee_lib.main,
          pauseOnUnhandledExceptions: true,
          extraArgs: extraDebuggingArgs,
        );
