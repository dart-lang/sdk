// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnableTest);
  });
}

@reflectiveTest
class EnableTest extends AbstractAnalysisServerIntegrationTest {
  test_call_enable() async {
    standardAnalysisSetup();

    // Toggle the value twice, and verify the changes.
    AnalyticsIsEnabledResult result1 = await sendAnalyticsIsEnabled();
    await sendAnalyticsEnable(!result1.enabled);

    AnalyticsIsEnabledResult result2 = await sendAnalyticsIsEnabled();
    expect(result2.enabled, !result1.enabled);

    await sendAnalyticsEnable(result1.enabled);
    result2 = await sendAnalyticsIsEnabled();
    expect(result2.enabled, result1.enabled);
  }
}
