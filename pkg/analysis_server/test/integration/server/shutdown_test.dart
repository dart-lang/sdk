// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ShutdownTest);
    defineReflectiveTests(ShutdownTest_Driver);
  });
}

class AbstractShutdownTest extends AbstractAnalysisServerIntegrationTest {
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

@reflectiveTest
class ShutdownTest extends AbstractShutdownTest {}

@reflectiveTest
class ShutdownTest_Driver extends AbstractShutdownTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
