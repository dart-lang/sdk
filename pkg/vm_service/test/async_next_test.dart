// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'async_next_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('async_next_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .stepOver() // foo()
        .stoppedAtLine('LINE_A')
        .stepOver() // foo()
        .asyncNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .stepOver() // foo()
        .asyncNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
