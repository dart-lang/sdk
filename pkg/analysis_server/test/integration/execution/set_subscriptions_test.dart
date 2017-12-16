// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
    defineReflectiveTests(SetSubscriptionsTest_PreviewDart2);
  });
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  test_subscribe() async {
    standardAnalysisSetup();
    // ignore: deprecated_member_use
    await sendExecutionSetSubscriptions([ExecutionService.LAUNCH_DATA]);
  }
}

@reflectiveTest
class SetSubscriptionsTest_PreviewDart2 extends SetSubscriptionsTest {
  @override
  bool get usePreviewDart2 => true;
}
