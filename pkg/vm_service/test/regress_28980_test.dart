// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'regress_28980_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_28980_lib.dart', args)
        .hasPausedAtStart()
        .markDartColonLibrariesDebuggable()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .setBreakpointAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stepInto()
        .stepInto()
        .stepInto()
        .resumeIsolate()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: false,
        );
