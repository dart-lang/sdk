// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsInvalidTest);
  });
}

@reflectiveTest
class SetSubscriptionsInvalidTest
    extends AbstractAnalysisServerIntegrationTest {
  test_setSubscriptions_invalidService() {
    // TODO(paulberry): verify that if an invalid service is specified, the
    // current subscriptions are unchanged.
    return server.send("server.setSubscriptions", {
      'subscriptions': ['bogus']
    }).then((_) {
      fail('setSubscriptions should have produced an error');
    }, onError: (error) {
      // The expected error occurred.
    });
  }
}
