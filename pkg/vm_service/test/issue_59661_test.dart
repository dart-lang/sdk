// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'issue_59661_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_59661_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_A')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'A',
            ['this', 'list'],
            [('list.toString()', '[3]')],
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_A_NAMED')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'A.named',
            ['this', 'list'],
            [('list.toString()', '[4]')],
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_A_NAMED2_BREAK_1')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'A.named2',
            ['this', 'list'],
            [
              ('list.toString()', '[5]'),
              ('this.list.toString()', '[1, 2]'),
            ],
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_A_NAMED2_BREAK_2')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'A.named2',
            ['this', 'list'],
            [('list.toString()', '[1, 2]')],
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_A_NAMED2_BREAK_3')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'A.named2',
            ['this', 'list'],
            [('list.toString()', '[6]')],
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_CLASS_B')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables(
            'B',
            ['this', 'list'],
            [('list.toString()', '[7]')],
          ),
        )
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: false,
          pauseOnExit: true,
        );
