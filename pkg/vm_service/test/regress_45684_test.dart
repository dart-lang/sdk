// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// Check that a try/finally is not treated as a try/catch:
// http://dartbug.com/45684.

import 'common/service_test_common.dart';
import 'regress_45684_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_45684_lib.dart', args)
        .hasStoppedWithUnhandledException()
        .stoppedAtLine('LINE_A')
        .run(
          testeeMain: testee_lib.main,
          pauseOnUnhandledExceptions: true,
        );
