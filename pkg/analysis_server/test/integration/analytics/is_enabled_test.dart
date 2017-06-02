// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsEnabledTest);
  });
}

@reflectiveTest
class IsEnabledTest extends AbstractAnalysisServerIntegrationTest {
  test_isEnabled() async {
    standardAnalysisSetup();

    AnalyticsIsEnabledResult result = await sendAnalyticsIsEnabled();
    // Very lightweight validation of the returned data.
    expect(result, isNotNull);
  }
}
