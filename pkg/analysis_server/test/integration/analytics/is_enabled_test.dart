// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsEnabledTest);
  });
}

@reflectiveTest
class IsEnabledTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_isEnabled() async {
    standardAnalysisSetup();

    var result = await sendAnalyticsIsEnabled();
    // Very lightweight validation of the returned data.
    expect(result, isNotNull);
  }
}
