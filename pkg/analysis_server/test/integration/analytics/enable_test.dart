// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnableTest);
  });
}

@reflectiveTest
class EnableTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_call_enable() async {
    standardAnalysisSetup();

    // Toggle the value twice; do light verification of the changes, as the
    // analysis server - when running on our CI bots - deliberately does not
    // send analytics info.
    var result1 = await sendAnalyticsIsEnabled();
    expect(result1.enabled, isNotNull);

    await sendAnalyticsEnable(!result1.enabled);
    var result2 = await sendAnalyticsIsEnabled();
    expect(result2.enabled, isNotNull);

    await sendAnalyticsEnable(result1.enabled);
  }
}
