// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'common/service_test_common.dart';
import 'issue_27287_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_27287_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepOver()
        // Check that debugger stops at assignment to top-level variable.
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
