// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for https://dartbug.com/60396.

import 'common/service_test_common.dart';
import 'regress_60396_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_60396_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtExit()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
