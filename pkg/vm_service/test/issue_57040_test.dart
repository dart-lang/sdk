// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'issue_57040_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_57040_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables('code', [
            'str',
          ], [
            ('() { return str.isNullOrEmpty; }()', 'false'),
            ('str.isNullOrEmpty', 'false'),
          ]),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables('code', [
            'str',
          ], [
            ('() { return str.isNullOrEmpty; }()', 'true'),
            ('str.isNullOrEmpty', 'true'),
          ]),
        )
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: false,
          pauseOnExit: true,
        );
