// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'common/service_test_common.dart';
import 'issue_27238_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_27238_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_A', column: 17) // on '='
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_A', column: 26) // on 'value'
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_B', column: 17) // on '='
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLineColumnWithTag(lineTag: 'LINE_B', column: 26) // on 'value'
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_E')
        .smartNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_F')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
