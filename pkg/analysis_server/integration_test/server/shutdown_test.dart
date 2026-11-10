// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
  Future<void> test_shutdown() async {
    await sendServerShutdown();
    await Future.delayed(Duration(seconds: 1));
    // Expect sendServerGetVersion to either throw or timeout, it should not
    // complete successfully.
    await expectLater(
      Future.sync(sendServerGetVersion).timeout(Duration(seconds: 1)),
      throwsA(anything),
      reason: 'Server still responsive after server.shutdown',
    );
  }
}
