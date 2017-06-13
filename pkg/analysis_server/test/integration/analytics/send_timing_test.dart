// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SendTimingTest);
  });
}

@reflectiveTest
class SendTimingTest extends AbstractAnalysisServerIntegrationTest {
  test_send_timing() async {
    standardAnalysisSetup();

    // Disable analytics.
    AnalyticsIsEnabledResult result1 = await sendAnalyticsIsEnabled();
    await sendAnalyticsEnable(false);

    // Send an event.
    await sendAnalyticsSendTiming('test-action', 100);

    // Restore the original value.
    await sendAnalyticsEnable(result1.enabled);
  }
}
