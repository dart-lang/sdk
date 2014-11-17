// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.shutdown;

import 'dart:async';

import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(Test);
}

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_shutdown() {
    return sendServerShutdown().then((_) {
      return new Future.delayed(new Duration(seconds: 1)).then((_) {
        sendServerGetVersion().then((_) {
          fail('Server still alive after server.shutdown');
        });
        // Give the server time to respond before terminating the test.
        return new Future.delayed(new Duration(seconds: 1));
      });
    });
  }
}
