// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'issue_59653_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_59653_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(
          testExpressionEvaluationAndAvailableVariables('analyzeExpression', [
            'this',
            'schema',
          ], [
            ('1', '1'),
            ('dispatchExpression(schema).toString()', 'C!'),
          ]),
        )
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: false,
          pauseOnExit: true,
        );
