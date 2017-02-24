// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  test_subscribe() async {
    standardAnalysisSetup();
    await sendExecutionSetSubscriptions([ExecutionService.LAUNCH_DATA]);
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
