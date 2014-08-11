// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.set.subscriptions.invalid.service;

import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_setSubscriptions_invalidService() {
    // TODO(paulberry): verify that if an invalid service is specified, the
    // current subscriptions are unchanged.
    return sendServerSetSubscriptions(['bogus'], checkTypes: false).then((_) {
      fail('setSubscriptions should have produced an error');
    }, onError: (error) {
      // The expected error occurred.
    });
  }
}

main() {
  runReflectiveTests(Test);
}
