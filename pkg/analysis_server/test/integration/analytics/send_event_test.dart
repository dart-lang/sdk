// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SendEventTest);
  });
}

@reflectiveTest
class SendEventTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_send_event() async {
    standardAnalysisSetup();

    // Disable analytics.
    var result1 = await sendAnalyticsIsEnabled();
    await sendAnalyticsEnable(false);

    // Send an event.
    await sendAnalyticsSendEvent('test-action');

    // Restore the original value.
    await sendAnalyticsEnable(result1.enabled);
  }
}
