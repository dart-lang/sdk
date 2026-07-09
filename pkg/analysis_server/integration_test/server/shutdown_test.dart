// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ShutdownTest);
  });
}

@reflectiveTest
class ShutdownTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_shutdown() {
    return sendServerShutdown().then((_) {
      return Future.delayed(Duration(seconds: 1)).then((_) {
        sendServerGetVersion().then((_) {
          fail('Server still alive after server.shutdown');
        });
        // Give the server time to respond before terminating the test.
        return Future.delayed(Duration(seconds: 1));
      });
    });
  }
}
